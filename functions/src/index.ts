/**
 * EventHub Cloud Functions.
 *
 * Three jobs the client cannot do safely or at all:
 *  1. `setRoleClaim` — copies the immutable profile role into a custom claim,
 *     the production path of `role()` in firestore.rules (no document read,
 *     nothing a client can tamper with).
 *  2. `notifyOrganizerOnReservation` — pushes every booking and cancellation
 *     to the event's organizer.
 *  3. `sendEventReminders` — the day-before reminder to ticket holders.
 *
 * Every push also lands in `users/{uid}/notifications` (in-app history, TTL
 * on `expiresAt`), and respects `users/{uid}/private/notifications`.
 * Contract with the app: `data.type` + ids, see
 * lib/features/notifications/application/notification_route.dart.
 */
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {getStorage} from "firebase-admin/storage";
import {logger, setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {defineBoolean} from "firebase-functions/params";
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";

initializeApp();
const db = getFirestore();

/**
 * Firestore-triggered functions must run in the database's location. The
 * `(default)` database is in `nam5` (US multi-region, see firebase.json),
 * whose triggers run in `us-central1`. Keep equal to
 * `AppConfig.functionsRegion` in the Flutter app.
 */
const REGION = "us-central1";
/** Time zone used to phrase times inside notifications. */
const TIME_ZONE = "Indian/Antananarivo";
/** Must match the channel created by the app and AndroidManifest.xml. */
const ANDROID_CHANNEL = "eventhub_default";
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

setGlobalOptions({region: REGION, maxInstances: 10});

/**
 * Reject callable requests without a valid App Check token. Off by default:
 * turn it on (`firebase functions:config` / `.env.<project>`:
 * ENFORCE_APP_CHECK=true) once the apps are registered in App Check and the
 * debug tokens of the development devices are declared — otherwise every
 * debug build is locked out.
 */
const ENFORCE_APP_CHECK = defineBoolean("ENFORCE_APP_CHECK", {
  default: false,
  description: "Refuse callable requests without an App Check token",
});

type NotificationType = "booking" | "cancellation" | "reminder" | "waitlist";

interface Reservation {
  eventId: string;
  userId: string;
  organizerId: string;
  userName: string;
  eventTitle: string;
  eventStartsAt: Timestamp;
  eventLocation: string;
  status: "confirmed" | "cancelled";
}

interface Preferences {
  eventReminders?: boolean;
  bookingAlerts?: boolean;
}

interface Notice {
  type: NotificationType;
  title: string;
  body: string;
  eventId: string;
  reservationId: string;
}

/** Tokens FCM will never accept again: their device documents are removed. */
const STALE_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

// --------------------------------------------------------------------------
// 1. Role claim
// --------------------------------------------------------------------------

export const setRoleClaim = onDocumentCreated("users/{uid}", async (event) => {
  const uid = event.params.uid;
  const role = event.data?.get("role");
  if (role !== "participant" && role !== "organizer") {
    logger.warn("Profile without a valid role, no claim set", {uid});
    return;
  }
  const auth = getAuth();
  const user = await auth.getUser(uid);
  await auth.setCustomUserClaims(uid, {...(user.customClaims ?? {}), role});
  logger.info("Role claim set", {uid, role});
});

// --------------------------------------------------------------------------
// 2. Bookings and cancellations → organizer
// --------------------------------------------------------------------------

export const notifyOrganizerOnReservation = onDocumentWritten(
  "reservations/{reservationId}",
  async (event) => {
    const before = event.data?.before.data() as Reservation | undefined;
    const after = event.data?.after.data() as Reservation | undefined;
    if (!after) return;

    // A creation and a re-booking after cancellation are both bookings.
    const booked =
      after.status === "confirmed" && before?.status !== "confirmed";
    const cancelled =
      before?.status === "confirmed" && after.status === "cancelled";
    if (!booked && !cancelled) return;

    // Holding a seat ends the wait, whatever the organizer's preferences.
    if (booked) {
      await db
        .doc(`events/${after.eventId}/waitlist/${after.userId}`)
        .delete();
    }

    const prefs = await preferencesOf(after.organizerId);
    if (prefs.bookingAlerts === false) return;

    await notify(after.organizerId, {
      type: booked ? "booking" : "cancellation",
      title: booked ? "Nouvelle réservation" : "Réservation annulée",
      body: booked
        ? `${after.userName} a réservé une place pour « ${after.eventTitle} ».`
        : `${after.userName} a libéré sa place pour « ${after.eventTitle} ».`,
      eventId: after.eventId,
      reservationId: event.params.reservationId,
    });
  },
);

// --------------------------------------------------------------------------
// 3. Day-before reminders → participants
// --------------------------------------------------------------------------

/**
 * Runs hourly and reminds holders of events starting between 23 h and 24 h
 * from now. The one-hour window matches the schedule, so each reservation
 * falls in exactly one run. Uses the `(status, eventStartsAt)` index.
 */
export const sendEventReminders = onSchedule(
  {schedule: "every 60 minutes", timeZone: TIME_ZONE},
  async () => {
    const result = await runEventReminders(Date.now());
    logger.info("Event reminders", result);
  },
);

/**
 * One reminder run at [nowMillis]. Exported so the integration tests can
 * drive it against the emulator without waiting for Cloud Scheduler.
 */
export async function runEventReminders(
  nowMillis: number,
): Promise<{candidates: number; sent: number}> {
  const snapshot = await db
    .collection("reservations")
    .where("status", "==", "confirmed")
    .where("eventStartsAt", ">=", Timestamp.fromMillis(nowMillis + 23 * HOUR))
    .where("eventStartsAt", "<", Timestamp.fromMillis(nowMillis + 24 * HOUR))
    .get();

  const time = new Intl.DateTimeFormat("fr-FR", {
    hour: "2-digit",
    minute: "2-digit",
    timeZone: TIME_ZONE,
  });

  let sent = 0;
  for (const doc of snapshot.docs) {
    const r = doc.data() as Reservation;
    const prefs = await preferencesOf(r.userId);
    if (prefs.eventReminders === false) continue;
    await notify(r.userId, {
      type: "reminder",
      title: `Demain : ${r.eventTitle}`,
      body:
        `Rendez-vous à ${time.format(r.eventStartsAt.toDate())} · ` +
        `${r.eventLocation}. Votre billet est dans l'application.`,
      eventId: r.eventId,
      reservationId: doc.id,
    });
    sent++;
  }
  return {candidates: snapshot.size, sent};
}

// --------------------------------------------------------------------------
// 3b. Waiting list → participants
// --------------------------------------------------------------------------

/**
 * When seats are released on an upcoming event, notifies as many waiting
 * people as seats freed, oldest entry first, and stamps `notifiedAt` so the
 * same person is not notified twice. No seat is held: the first to book gets
 * it (announced as such in the message). A booking removes the entry (see
 * notifyOrganizerOnReservation).
 */
export const notifyWaitlistOnSeatRelease = onDocumentUpdated(
  "events/{eventId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const freed =
      (after.availablePlaces as number) - (before.availablePlaces as number);
    if (freed <= 0) return;
    if ((after.startsAt as Timestamp).toMillis() <= Date.now()) return;

    const queue = await event.data!.after.ref
      .collection("waitlist")
      .orderBy("createdAt")
      .limit(200)
      .get();
    const next = queue.docs.filter((d) => !d.get("notifiedAt")).slice(0, freed);

    for (const entry of next) {
      const uid = entry.get("userId") as string;
      const prefs = await preferencesOf(uid);
      if (prefs.eventReminders !== false) {
        await notify(uid, {
          type: "waitlist",
          title: "Une place s'est libérée",
          body:
            `« ${after.title} » : ${freed} place${freed > 1 ? "s" : ""} ` +
            "disponible" +
            `${freed > 1 ? "s" : ""}. Premier arrivé, premier servi.`,
          eventId: event.params.eventId,
          reservationId: "",
        });
      }
      await entry.ref.update({notifiedAt: FieldValue.serverTimestamp()});
    }
    logger.info("Waitlist notified", {
      eventId: event.params.eventId,
      freed,
      waiting: queue.size,
      notified: next.length,
    });
  },
);

// --------------------------------------------------------------------------
// 4. Account deletion
// --------------------------------------------------------------------------

/** Replaces personal data kept on records other people rely on. */
const DELETED_NAME = "Compte supprimé";
const DELETED_EMAIL = "supprime@eventhub.invalid";

/**
 * Deletes the caller's account and everything that belongs to it.
 *
 * The client cannot do this: the rules forbid deleting a profile, and the
 * cascade touches other users' data (seat counters, guest lists). Order
 * matters — refusals first, then shared data, then private data, and the
 * Auth user last so a failure mid-way can simply be retried.
 *
 *  - organizer with an upcoming event that has participants → refused
 *    (`failed-precondition`): people hold tickets for it;
 *  - organizer's events and their subcollections, and cover images → deleted;
 *  - reservations held by the user → upcoming ones cancelled and their seat
 *    released; all anonymised (organizers keep an accurate history, without
 *    the person's name or email);
 *  - waiting-list entries → deleted; reviews → anonymised;
 *  - `users/{uid}` and its subcollections (devices, preferences,
 *    notifications, favourites), avatar files, then the Auth user.
 */
export const deleteAccount = onCall(async (request) => {
  if (ENFORCE_APP_CHECK.value() && !request.app) {
    throw new HttpsError(
      "permission-denied",
      "Application non vérifiée. Mettez EventHub à jour puis réessayez.",
    );
  }
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Vous devez être connecté.");
  }
  const userRef = db.collection("users").doc(uid);
  const profile = await userRef.get();
  const bucket = getStorage().bucket();
  const now = Date.now();

  if (profile.get("role") === "organizer") {
    const events = await db
      .collection("events")
      .where("organizerId", "==", uid)
      .get();
    const blocking = events.docs.filter(
      (d) =>
        (d.get("startsAt") as Timestamp).toMillis() > now &&
        (d.get("capacity") as number) - (d.get("availablePlaces") as number) > 0,
    );
    if (blocking.length > 0) {
      throw new HttpsError(
        "failed-precondition",
        `Suppression impossible : ${blocking.length} événement` +
          `${blocking.length > 1 ? "s" : ""} à venir ` +
          `${blocking.length > 1 ? "ont" : "a"} des participants. ` +
          "Attendez qu'ils soient passés ou que les places soient libérées.",
      );
    }
    for (const event of events.docs) {
      await db.recursiveDelete(event.ref);
    }
    await bucket.deleteFiles({prefix: `events/${uid}/`});
  }

  const reservations = await db
    .collection("reservations")
    .where("userId", "==", uid)
    .get();
  for (const doc of reservations.docs) {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(doc.ref);
      const r = snap.data() as Reservation | undefined;
      if (!r) return;
      const releases =
        r.status === "confirmed" && r.eventStartsAt.toMillis() > Date.now();
      const eventRef = db.collection("events").doc(r.eventId);
      const event = releases ? await tx.get(eventRef) : undefined;

      if (event?.exists) {
        tx.update(eventRef, {
          availablePlaces: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
      tx.update(doc.ref, {
        userName: DELETED_NAME,
        userEmail: DELETED_EMAIL,
        ...(releases ? {status: "cancelled", cancelledAt: Timestamp.now()} : {}),
      });
    });
  }

  const waitlist = await db
    .collectionGroup("waitlist")
    .where("userId", "==", uid)
    .orderBy("createdAt")
    .get();
  await Promise.all(waitlist.docs.map((d) => d.ref.delete()));

  const reviews = await db
    .collection("reviews")
    .where("authorId", "==", uid)
    .orderBy("createdAt", "desc")
    .get();
  await Promise.all(
    reviews.docs.map((d) => d.ref.update({authorName: DELETED_NAME})),
  );

  await db.recursiveDelete(userRef);
  await bucket.deleteFiles({prefix: `avatars/${uid}/`});
  await getAuth().deleteUser(uid);

  logger.info("Account deleted", {
    uid,
    reservations: reservations.size,
    waitlist: waitlist.size,
    reviews: reviews.size,
  });
  return {deleted: true};
});

// --------------------------------------------------------------------------
// Helpers
// --------------------------------------------------------------------------

async function preferencesOf(uid: string): Promise<Preferences> {
  const snap = await db.doc(`users/${uid}/private/notifications`).get();
  return (snap.data() as Preferences | undefined) ?? {};
}

/** Writes the in-app notification, then pushes to every registered device. */
async function notify(uid: string, notice: Notice): Promise<void> {
  const user = db.collection("users").doc(uid);

  await user.collection("notifications").add({
    ...notice,
    createdAt: FieldValue.serverTimestamp(),
    readAt: null,
    expiresAt: Timestamp.fromMillis(Date.now() + 30 * DAY),
  });

  const devices = await user.collection("devices").get();
  if (devices.empty) return;

  const response = await getMessaging().sendEachForMulticast({
    tokens: devices.docs.map((d) => d.get("token") as string),
    notification: {title: notice.title, body: notice.body},
    data: {
      type: notice.type,
      eventId: notice.eventId,
      reservationId: notice.reservationId,
    },
    android: {priority: "high", notification: {channelId: ANDROID_CHANNEL}},
    apns: {payload: {aps: {sound: "default"}}},
  });

  const stale = response.responses.flatMap((r, i) =>
    !r.success && STALE_TOKEN_CODES.has(r.error?.code ?? "")
      ? [devices.docs[i].ref.delete()]
      : [],
  );
  await Promise.all(stale);
  logger.info("Push sent", {
    uid,
    type: notice.type,
    success: response.successCount,
    failure: response.failureCount,
    removedTokens: stale.length,
  });
}
