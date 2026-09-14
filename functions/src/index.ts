/**
 * EventHub Cloud Functions.
 *
 * The jobs the client cannot do safely or at all:
 *  1. `setRoleClaim` — copies the immutable profile role into a custom claim,
 *     the production path of `role()` in firestore.rules.
 *  2. `notifyOrganizerOnReservation` — pushes every booking and cancellation
 *     to the event's organizer.
 *  3. `sendEventReminders` — the day-before reminder to ticket holders;
 *     `notifyWaitlistOnSeatRelease` — a seat opened for people waiting.
 *  4. `deleteAccount` — the account deletion cascade.
 *  5. Public organizer profiles (F-10): `syncOrganizerProfile`,
 *     `onFollowWritten`, `onEventWritten` (event count + "new event" push to
 *     followers), `aggregateOrganizerRating`.
 *  6. Social proof (F-07): `aggregateAttendance`.
 *  7. Moderation (F-19): `onReportCreated`, `moderateContent`.
 *  8. Public event page with Open Graph tags (F-08): `publicEventPage`,
 *     served by Firebase Hosting on `/e/{eventId}`.
 *
 * Every push also lands in `users/{uid}/notifications` (in-app history, TTL
 * on `expiresAt`), and respects `users/{uid}/private/notifications`.
 * Contract with the app: `data.type` + ids, see
 * lib/features/notifications/application/notification_route.dart.
 *
 * Counters are maintained by triggers, which Firebase delivers **at least
 * once**. Every counter update therefore goes through `once()`, which
 * records the trigger's event id in the same transaction as the write.
 */
import {createHash} from "node:crypto";

import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {
  DocumentData,
  FieldPath,
  FieldValue,
  QueryDocumentSnapshot,
  Timestamp,
  Transaction,
  getFirestore,
} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {getStorage} from "firebase-admin/storage";
import {logger, setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
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

/** Public origin of the Hosting site: shared links and Open Graph URLs. */
const PUBLIC_ORIGIN = "https://eventhub-d411f.web.app";
/** Android package, for the "open in the app" intent on the public page. */
const ANDROID_PACKAGE = "com.example.eventhub";

type NotificationType =
  | "booking"
  | "cancellation"
  | "reminder"
  | "waitlist"
  | "newEvent"
  | "eventRemoved"
  | "reviewHidden"
  | "staffInvite"
  | "staffJoined"
  | "staffRemoved";

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
  followedOrganizers?: boolean;
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
  // A profile written from the console or an import script may have no
  // Auth account behind it: nothing to attach a claim to, and retrying
  // would not change that.
  const user = await auth.getUser(uid).catch((e: {code?: string}) => {
    if (e.code === "auth/user-not-found") return null;
    throw e;
  });
  if (!user) {
    logger.warn("Profile without an Auth account, no claim set", {uid});
    return;
  }
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
    // A moderation removal cancels every seat at once and tells the organizer
    // in a single message (see removeEventByModeration), not one per guest.
    if (cancelled && (after as {cancelledBy?: string}).cancelledBy === "moderation") {
      return;
    }

    // Holding a seat ends the wait, whatever the organizer's preferences.
    if (booked) {
      await db
        .doc(`events/${after.eventId}/waitlist/${after.userId}`)
        .delete();
    }

    // The organizer and every co-organizer (F-16), each with their own
    // preference.
    const eventSnap = await db.doc(`events/${after.eventId}`).get();
    const staff = (eventSnap.get("staffIds") as string[] | undefined) ?? [];
    for (const uid of new Set([after.organizerId, ...staff])) {
      const prefs = await preferencesOf(uid);
      if (prefs.bookingAlerts === false) continue;
      await notify(uid, {
        type: booked ? "booking" : "cancellation",
        title: booked ? "Nouvelle réservation" : "Réservation annulée",
        body: booked ?
          `${after.userName} a réservé une place pour « ${after.eventTitle} ».` :
          `${after.userName} a libéré sa place pour « ${after.eventTitle} ».`,
        eventId: after.eventId,
        reservationId: event.params.reservationId,
      });
    }
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

  // The social-proof strip must not keep showing the name of someone who
  // left, past events included.
  for (const doc of reservations.docs) {
    await setRecentAttendee(doc.get("eventId") as string, uid, null);
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

  // Co-organizer seats on other people's events, and pending invitations.
  const staffed = await db
    .collection("events")
    .where("staffIds", "array-contains", uid)
    .get();
  await Promise.all(
    staffed.docs.map((d) =>
      d.ref.update({staffIds: FieldValue.arrayRemove(uid)}),
    ),
  );
  const invitations = await userRef.collection("staffInvitations").get();
  await Promise.all(
    invitations.docs.map((d) =>
      db.doc(`events/${d.id}/invitations/${uid}`).delete(),
    ),
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
// 5. Public organizer profile (F-10)
// --------------------------------------------------------------------------

/**
 * Keeps `organizers/{uid}` — the public, read-only face of an organizer —
 * in step with the private profile. Only fields the organizer chose to
 * publish are copied; the email and the role never leave `users/{uid}`.
 * Deleting the profile (account deletion) deletes the public page and its
 * follower list.
 */
export const syncOrganizerProfile = onDocumentWritten(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const ref = db.doc(`organizers/${uid}`);
    const after = event.data?.after.data();

    if (!after || after.role !== "organizer") {
      if (event.data?.before.get("role") === "organizer") {
        await db.recursiveDelete(ref);
      }
      return;
    }
    await ref.set(
      {
        name: after.name,
        bio: typeof after.bio === "string" ? after.bio : "",
        photoUrl: after.photoUrl ?? null,
        memberSince: after.createdAt ?? null,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  },
);

/**
 * `users/{uid}/following/{organizerId}` is private to the follower; this
 * mirrors it into `organizers/{id}/followers/{uid}` (server-only, used for
 * the new-event fan-out) and maintains the public `followerCount`. The
 * mirror doubles as an idempotency check.
 */
export const onFollowWritten = onDocumentWritten(
  "users/{uid}/following/{organizerId}",
  async (event) => {
    const {uid, organizerId} = event.params;
    const created = !event.data?.before.exists && event.data?.after.exists;
    const deleted = event.data?.before.exists && !event.data?.after.exists;
    if (!created && !deleted) return;

    const organizer = db.doc(`organizers/${organizerId}`);
    const mirror = organizer.collection("followers").doc(uid);

    await once(event.id, async (tx) => {
      const [org, existing] = await Promise.all([
        tx.get(organizer),
        tx.get(mirror),
      ]);
      if (created && org.exists && !existing.exists) {
        tx.set(mirror, {userId: uid, createdAt: FieldValue.serverTimestamp()});
        tx.update(organizer, {followerCount: FieldValue.increment(1)});
      }
      if (deleted && existing.exists) {
        tx.delete(mirror);
        if (org.exists) {
          tx.update(organizer, {followerCount: FieldValue.increment(-1)});
        }
      }
    });
  },
);

/**
 * On event creation: `eventCount` goes up and every follower who did not
 * opt out is told about it. On deletion: the count goes down and the
 * event's aggregate document goes away with it.
 */
export const onEventWritten = onDocumentWritten(
  "events/{eventId}",
  async (event) => {
    const eventId = event.params.eventId;
    const created = !event.data?.before.exists && event.data?.after.exists;
    const deleted = event.data?.before.exists && !event.data?.after.exists;
    if (!created && !deleted) return;

    const data = (created ? event.data!.after : event.data!.before).data()!;
    const organizer = db.doc(`organizers/${data.organizerId}`);
    let announce = false;

    await once(event.id, async (tx) => {
      const org = await tx.get(organizer);
      if (org.exists) {
        tx.update(organizer, {
          eventCount: FieldValue.increment(created ? 1 : -1),
        });
      }
      if (deleted) tx.delete(db.doc(`aggregates/event_${eventId}`));
      announce = Boolean(created);
    });

    if (announce && (data.startsAt as Timestamp).toMillis() > Date.now()) {
      await announceToFollowers(eventId, data);
    }
  },
);

/** Pages through the follower mirror, 300 at a time, 20 pushes in flight. */
async function announceToFollowers(
  eventId: string,
  data: DocumentData,
): Promise<void> {
  const when = new Intl.DateTimeFormat("fr-FR", {
    weekday: "long",
    day: "numeric",
    month: "long",
    hour: "2-digit",
    minute: "2-digit",
    timeZone: TIME_ZONE,
  }).format((data.startsAt as Timestamp).toDate());

  const followers = db.collection(`organizers/${data.organizerId}/followers`);
  let cursor: QueryDocumentSnapshot | undefined;
  let notified = 0;

  for (;;) {
    let query = followers.orderBy(FieldPath.documentId()).limit(300);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    if (page.empty) break;

    for (let i = 0; i < page.docs.length; i += 20) {
      await Promise.all(
        page.docs.slice(i, i + 20).map(async (follower) => {
          const prefs = await preferencesOf(follower.id);
          if (prefs.followedOrganizers === false) return;
          await notify(follower.id, {
            type: "newEvent",
            title: `${data.organizerName} publie un événement`,
            body: `« ${data.title} » · ${when} · ${data.location}.`,
            eventId,
            reservationId: "",
          });
          notified++;
        }),
      );
    }
    cursor = page.docs[page.docs.length - 1];
    if (page.size < 300) break;
  }
  logger.info("New event announced", {eventId, notified});
}

/**
 * `ratingSum` / `ratingCount` on the organizer, over the **visible** reviews
 * of their events: a review hidden by moderation stops counting, and counts
 * again if an admin restores it. Only the rating delta is applied, so an
 * edit that changes the comment alone costs nothing.
 */
export const aggregateOrganizerRating = onDocumentWritten(
  "reviews/{reviewId}",
  async (event) => {
    const counted = (d: DocumentData | undefined): number | null =>
      d && d.hidden !== true && typeof d.rating === "number" ? d.rating : null;
    const before = counted(event.data?.before.data());
    const after = counted(event.data?.after.data());
    if (before === after) return;

    const review = (event.data?.after.data() ?? event.data?.before.data())!;
    const eventDoc = await db.doc(`events/${review.eventId}`).get();
    if (!eventDoc.exists) return;
    const organizer = db.doc(`organizers/${eventDoc.get("organizerId")}`);

    await once(event.id, async (tx) => {
      if (!(await tx.get(organizer)).exists) return;
      tx.update(organizer, {
        ratingSum: FieldValue.increment((after ?? 0) - (before ?? 0)),
        ratingCount: FieldValue.increment(
          (after === null ? 0 : 1) - (before === null ? 0 : 1),
        ),
      });
    });
  },
);

// --------------------------------------------------------------------------
// 5b. Co-organizers (F-16)
// --------------------------------------------------------------------------

/** Team size, owner excluded. Mirrored in firestore.rules and the app. */
export const MAX_STAFF = 10;

/**
 * The owner invites an organizer by email. The invitation is written twice —
 * under the event (the team sees who is pending) and under the invitee (their
 * inbox) — and pushed. Only an organizer account can be invited: a
 * co-organizer works in the organizer area (guest list, door scanner).
 */
export const inviteCoOrganizer = onCall(async (request) => {
  const uid = requireSignedIn(request);
  const {eventId, email} = (request.data ?? {}) as {
    eventId?: unknown;
    email?: unknown;
  };
  if (typeof eventId !== "string" || !eventId || eventId.includes("/")) {
    throw new HttpsError("invalid-argument", "Événement invalide.");
  }
  if (typeof email !== "string" || !/^[^@\s]+@[^@\s]+$/.test(email.trim())) {
    throw new HttpsError("invalid-argument", "Adresse email invalide.");
  }

  const eventRef = db.doc(`events/${eventId}`);
  const event = await eventRef.get();
  if (!event.exists) throw new HttpsError("not-found", "Événement introuvable.");
  if (event.get("organizerId") !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Seul l'organisateur principal compose l'équipe.",
    );
  }
  if ((event.get("startsAt") as Timestamp).toMillis() <= Date.now()) {
    throw new HttpsError("failed-precondition", "Cet événement est passé.");
  }

  const invitee = await getAuth()
    .getUserByEmail(email.trim().toLowerCase())
    .catch(() => {
      throw new HttpsError("not-found", "Aucun compte EventHub avec cet email.");
    });
  if (invitee.uid === uid) {
    throw new HttpsError(
      "failed-precondition",
      "Vous êtes déjà l'organisateur de cet événement.",
    );
  }
  const profile = await db.doc(`users/${invitee.uid}`).get();
  if (profile.get("role") !== "organizer") {
    throw new HttpsError(
      "failed-precondition",
      "Ce compte n'est pas organisateur : seul un organisateur peut co-organiser.",
    );
  }
  const staff = (event.get("staffIds") as string[] | undefined) ?? [];
  if (staff.includes(invitee.uid)) {
    throw new HttpsError(
      "failed-precondition",
      "Cette personne fait déjà partie de l'équipe.",
    );
  }
  const pending = (
    await eventRef
      .collection("invitations")
      .where("status", "==", "pending")
      .count()
      .get()
  ).data().count;
  if (staff.length + pending >= MAX_STAFF) {
    throw new HttpsError(
      "failed-precondition",
      `Équipe complète : ${MAX_STAFF} co-organisateurs au plus.`,
    );
  }

  const invitation = {
    eventId,
    userId: invitee.uid,
    email: invitee.email ?? email.trim().toLowerCase(),
    name: (profile.get("name") as string | undefined) ?? "",
    invitedBy: uid,
    invitedByName: event.get("organizerName") as string,
    eventTitle: event.get("title") as string,
    eventStartsAt: event.get("startsAt") as Timestamp,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
  };
  const batch = db.batch();
  batch.set(eventRef.collection("invitations").doc(invitee.uid), invitation);
  batch.set(
    db.doc(`users/${invitee.uid}/staffInvitations/${eventId}`),
    invitation,
  );
  await batch.commit();

  await notify(invitee.uid, {
    type: "staffInvite",
    title: "Invitation à co-organiser",
    body:
      `${invitation.invitedByName} vous propose de co-organiser ` +
      `« ${invitation.eventTitle} ».`,
    eventId,
    reservationId: "",
  });
  await audit("staff.invited", {eventId, userId: invitee.uid, by: uid});
  return {userId: invitee.uid, name: invitation.name};
});

/** The invitee accepts (joins `staffIds`) or declines. */
export const respondToStaffInvite = onCall(async (request) => {
  const uid = requireSignedIn(request);
  const {eventId, accept} = (request.data ?? {}) as {
    eventId?: unknown;
    accept?: unknown;
  };
  if (typeof eventId !== "string" || !eventId || eventId.includes("/")) {
    throw new HttpsError("invalid-argument", "Événement invalide.");
  }
  if (typeof accept !== "boolean") {
    throw new HttpsError("invalid-argument", "Requête invalide.");
  }

  const eventRef = db.doc(`events/${eventId}`);
  const inviteRef = eventRef.collection("invitations").doc(uid);
  const mirrorRef = db.doc(`users/${uid}/staffInvitations/${eventId}`);

  const outcome = await db.runTransaction(async (tx) => {
    const [invite, event] = await Promise.all([
      tx.get(inviteRef),
      tx.get(eventRef),
    ]);
    if (!invite.exists || invite.get("status") !== "pending" || !event.exists) {
      throw new HttpsError("not-found", "Cette invitation n'est plus valable.");
    }
    const staff = (event.get("staffIds") as string[] | undefined) ?? [];
    if (accept && !staff.includes(uid) && staff.length >= MAX_STAFF) {
      throw new HttpsError("failed-precondition", "L'équipe est déjà complète.");
    }
    const update = {
      status: accept ? "accepted" : "declined",
      respondedAt: FieldValue.serverTimestamp(),
    };
    tx.update(inviteRef, update);
    tx.set(mirrorRef, update, {merge: true});
    if (accept) tx.update(eventRef, {staffIds: FieldValue.arrayUnion(uid)});
    return {
      ownerId: event.get("organizerId") as string,
      title: event.get("title") as string,
      name: (invite.get("name") as string | undefined) ?? "",
    };
  });

  if (accept) {
    await notify(outcome.ownerId, {
      type: "staffJoined",
      title: "Nouveau co-organisateur",
      body:
        `${outcome.name || "Un organisateur"} a rejoint l'équipe de ` +
        `« ${outcome.title} ».`,
      eventId,
      reservationId: "",
    });
  }
  await audit(accept ? "staff.accepted" : "staff.declined", {eventId, uid});
  return {accepted: accept};
});

/**
 * The owner removes a member or cancels a pending invitation; a member may
 * also leave on their own. The owner can never be removed.
 */
export const removeCoOrganizer = onCall(async (request) => {
  const uid = requireSignedIn(request);
  const {eventId, userId} = (request.data ?? {}) as {
    eventId?: unknown;
    userId?: unknown;
  };
  if (
    typeof eventId !== "string" || !eventId || eventId.includes("/") ||
    typeof userId !== "string" || !userId || userId.includes("/")
  ) {
    throw new HttpsError("invalid-argument", "Requête invalide.");
  }
  const eventRef = db.doc(`events/${eventId}`);
  const event = await eventRef.get();
  if (!event.exists) throw new HttpsError("not-found", "Événement introuvable.");

  const ownerId = event.get("organizerId") as string;
  const leaving = userId === uid;
  if (!leaving && ownerId !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Seul l'organisateur principal retire un membre de l'équipe.",
    );
  }
  if (userId === ownerId) {
    throw new HttpsError(
      "failed-precondition",
      "L'organisateur principal ne quitte pas son propre événement.",
    );
  }
  const wasMember = (
    (event.get("staffIds") as string[] | undefined) ?? []
  ).includes(userId);

  const batch = db.batch();
  batch.update(eventRef, {staffIds: FieldValue.arrayRemove(userId)});
  batch.delete(eventRef.collection("invitations").doc(userId));
  batch.delete(db.doc(`users/${userId}/staffInvitations/${eventId}`));
  await batch.commit();

  if (wasMember && !leaving) {
    await notify(userId, {
      type: "staffRemoved",
      title: "Retiré de l'équipe",
      body: `Vous ne co-organisez plus « ${event.get("title")} ».`,
      eventId,
      reservationId: "",
    });
  }
  await audit(leaving ? "staff.left" : "staff.removed", {
    eventId,
    userId,
    by: uid,
  });
  return {removed: true};
});

// --------------------------------------------------------------------------
// 6. Social proof (F-07)
// --------------------------------------------------------------------------

/** How many names the "who's going" strip keeps, most recent first. */
const RECENT_ATTENDEES = 8;

/**
 * Maintains `aggregates/event_{eventId}.recentAttendees`: the short names
 * ("Hery R.") of the last people who booked. The head count itself is not
 * stored — the event's `capacity - availablePlaces` is already exact.
 *
 * Entries are keyed by a truncated SHA-256 of the uid, so the list can be
 * updated on cancellation without publishing anybody's uid.
 */
export const aggregateAttendance = onDocumentWritten(
  "reservations/{reservationId}",
  async (event) => {
    const before = event.data?.before.data() as Reservation | undefined;
    const after = event.data?.after.data() as Reservation | undefined;
    if (!after) return;
    const booked =
      after.status === "confirmed" && before?.status !== "confirmed";
    const cancelled =
      before?.status === "confirmed" && after.status === "cancelled";
    if (!booked && !cancelled) return;

    await setRecentAttendee(
      after.eventId,
      after.userId,
      booked ? shortName(after.userName) : null,
    );
  },
);

/**
 * Puts [userId] at the head of the strip under [name], or removes them when
 * [name] is null. Idempotent by construction: the entry is replaced, never
 * appended twice.
 */
async function setRecentAttendee(
  eventId: string,
  userId: string,
  name: string | null,
): Promise<void> {
  const ref = db.doc(`aggregates/event_${eventId}`);
  const key = attendeeKey(userId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = (snap.get("recentAttendees") ?? []) as Array<{
      key: string;
      name: string;
    }>;
    const others = current.filter((a) => a.key !== key);
    if (!name && others.length === current.length) return;
    const next = name ?
      [{key, name}, ...others].slice(0, RECENT_ATTENDEES) :
      others;
    tx.set(
      ref,
      {
        eventId,
        recentAttendees: next,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  });
}

export function attendeeKey(userId: string): string {
  return createHash("sha256").update(userId).digest("hex").slice(0, 16);
}

/** "Jean-Marc Rakotomalala" → "Jean-Marc R."; a single word stays whole. */
export function shortName(fullName: string): string | null {
  if (!fullName || fullName === DELETED_NAME) return null;
  const parts = fullName.trim().split(/\s+/);
  const first = parts[0].slice(0, 30);
  return parts.length > 1 ?
    `${first} ${parts[parts.length - 1][0].toUpperCase()}.` :
    first;
}

// --------------------------------------------------------------------------
// 7. Moderation (F-19)
// --------------------------------------------------------------------------

/** Distinct reporters before a review is hidden pending review. */
export const HIDE_REVIEW_THRESHOLD = 3;

type TargetType = "event" | "user" | "review";

/**
 * Each report updates the moderation queue entry of its target (one entry
 * per target, sorted by report count in the console) and the audit trail.
 * Report ids are one-per-account (see firestore.rules), so the count is a
 * count of distinct people.
 *
 * A review reaching [HIDE_REVIEW_THRESHOLD] is hidden at once — a review is
 * cheap to hide and cheap to restore, and abusive text should not wait for
 * office hours. Events and accounts are never removed automatically: people
 * hold tickets, so a human decides.
 */
export const onReportCreated = onDocumentCreated(
  "reports/{reportId}",
  async (event) => {
    const report = event.data?.data();
    if (!report) return;
    const targetType = report.targetType as TargetType;
    const targetId = report.targetId as string;

    const count = (
      await db
        .collection("reports")
        .where("targetType", "==", targetType)
        .where("targetId", "==", targetId)
        .count()
        .get()
    ).data().count;

    let hidden = false;
    if (targetType === "review" && count >= HIDE_REVIEW_THRESHOLD) {
      const review = db.doc(`reviews/${targetId}`);
      hidden = await db.runTransaction(async (tx) => {
        const snap = await tx.get(review);
        // An admin's decision (moderatedAt) is final: restored stays restored.
        if (!snap.exists || snap.get("hidden") || snap.get("moderatedAt")) {
          return false;
        }
        tx.update(review, {hidden: true, hiddenAt: FieldValue.serverTimestamp()});
        return true;
      });
      if (hidden) await notifyReviewAuthor(targetId, null);
    }

    await db.doc(`moderationQueue/${targetType}_${targetId}`).set(
      {
        targetType,
        targetId,
        reportCount: count,
        lastReason: report.reason,
        autoHidden: hidden ? true : FieldValue.delete(),
        status: "open",
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    await audit("report.received", {
      targetType,
      targetId,
      reason: report.reason,
      reportCount: count,
      autoHidden: hidden,
    });
  },
);

type ModerationAction =
  | "hide"
  | "restore"
  | "removeEvent"
  | "suspend"
  | "reinstate"
  | "dismiss";

/** What an admin may decide, per target. Mirrored in the app's policy. */
export const ACTIONS_BY_TARGET: Record<TargetType, ModerationAction[]> = {
  review: ["hide", "restore", "dismiss"],
  event: ["removeEvent", "dismiss"],
  user: ["suspend", "reinstate", "dismiss"],
};

/** Decisions that change something for a person must say why. */
const NOTE_REQUIRED: ModerationAction[] = ["removeEvent", "suspend"];

/**
 * Admin decision on a queue entry.
 *
 *  - review — `hide` / `restore` stamp `moderatedAt` (the automatic threshold
 *    never overrides a human decision); the author is told when hidden;
 *  - event — `removeEvent` cancels every confirmed seat, tells each holder
 *    and the organizer once, then deletes the event, its subcollections and
 *    its banner;
 *  - user — `suspend` disables the Auth account and revokes its refresh
 *    tokens (existing ID tokens expire within the hour); `reinstate` undoes
 *    it. An admin cannot suspend themselves;
 *  - any — `dismiss` closes the entry without touching the content.
 *
 * Every decision is appended to `moderationQueue/{id}/decisions` and to the
 * audit trail. Callable only with the `admin` custom claim.
 */
export const moderateContent = onCall(async (request) => {
  const adminUid = requireAdmin(request);
  const {targetType, targetId, action, note} = (request.data ?? {}) as {
    targetType?: string;
    targetId?: string;
    action?: string;
    note?: unknown;
  };
  if (
    !(targetType === "event" || targetType === "user" || targetType === "review") ||
    typeof targetId !== "string" ||
    targetId.length === 0 ||
    targetId.length > 200 ||
    targetId.includes("/")
  ) {
    throw new HttpsError("invalid-argument", "Requête de modération invalide.");
  }
  const allowed = ACTIONS_BY_TARGET[targetType];
  if (!allowed.includes(action as ModerationAction)) {
    throw new HttpsError(
      "invalid-argument",
      "Cette décision ne s'applique pas à ce type de contenu.",
    );
  }
  const decision = action as ModerationAction;
  const text = typeof note === "string" ? note.trim() : "";
  if (text.length > 500) {
    throw new HttpsError("invalid-argument", "Note : 500 caractères maximum.");
  }
  if (NOTE_REQUIRED.includes(decision) && text.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Expliquez la décision : la personne concernée la recevra.",
    );
  }

  let outcome: Record<string, unknown> = {};
  switch (decision) {
    case "hide":
    case "restore": {
      const review = db.doc(`reviews/${targetId}`);
      if (!(await review.get()).exists) {
        throw new HttpsError("not-found", "Avis introuvable.");
      }
      await review.update({
        hidden: decision === "hide",
        moderatedAt: FieldValue.serverTimestamp(),
        moderatedBy: adminUid,
      });
      if (decision === "hide") await notifyReviewAuthor(targetId, text || null);
      break;
    }
    case "removeEvent":
      outcome = await removeEventByModeration(targetId, text);
      break;
    case "suspend":
    case "reinstate": {
      if (targetId === adminUid) {
        throw new HttpsError(
          "failed-precondition",
          "Vous ne pouvez pas suspendre votre propre compte.",
        );
      }
      const auth = getAuth();
      await auth.getUser(targetId).catch(() => {
        throw new HttpsError("not-found", "Compte introuvable.");
      });
      await auth.updateUser(targetId, {disabled: decision === "suspend"});
      if (decision === "suspend") await auth.revokeRefreshTokens(targetId);
      const organizer = db.doc(`organizers/${targetId}`);
      if ((await organizer.get()).exists) {
        await organizer.update({
          suspended: decision === "suspend" ? true : FieldValue.delete(),
        });
      }
      break;
    }
    case "dismiss":
      break;
  }

  const entry = db.doc(`moderationQueue/${targetType}_${targetId}`);
  await entry.set(
    {
      targetType,
      targetId,
      status: decision === "dismiss" ? "dismissed" : "resolved",
      decision,
      decisionNote: text || FieldValue.delete(),
      decidedBy: adminUid,
      decidedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  await entry.collection("decisions").add({
    action: decision,
    note: text,
    by: adminUid,
    at: FieldValue.serverTimestamp(),
  });
  await audit(`moderation.${decision}`, {
    targetType,
    targetId,
    by: adminUid,
    note: text,
    ...outcome,
  });
  return {ok: true, ...outcome};
});

/** Cancels, notifies, deletes. Returns how many seats were cancelled. */
async function removeEventByModeration(
  eventId: string,
  note: string,
): Promise<{cancelledReservations: number}> {
  const eventRef = db.doc(`events/${eventId}`);
  const snap = await eventRef.get();
  if (!snap.exists) throw new HttpsError("not-found", "Événement introuvable.");
  const event = snap.data()!;

  const seats = await db
    .collection("reservations")
    .where("eventId", "==", eventId)
    .where("status", "==", "confirmed")
    .get();

  for (const doc of seats.docs) {
    // `cancelledBy` tells notifyOrganizerOnReservation to stay silent: the
    // organizer gets one message below, not one per guest.
    await doc.ref.update({
      status: "cancelled",
      cancelledAt: Timestamp.now(),
      cancelledBy: "moderation",
    });
    await notify(doc.get("userId") as string, {
      type: "eventRemoved",
      title: "Événement annulé",
      body:
        `« ${event.title} » a été retiré d'EventHub. ` +
        "Votre réservation est annulée.",
      eventId,
      reservationId: doc.id,
    });
  }

  await notify(event.organizerId as string, {
    type: "eventRemoved",
    title: "Événement retiré par la modération",
    body: `« ${event.title} » : ${note}`,
    eventId,
    reservationId: "",
  });

  await db.recursiveDelete(eventRef);
  const banner = storagePathFromUrl(event.imageUrl);
  if (banner?.startsWith("events/")) {
    await getStorage()
      .bucket()
      .file(banner)
      .delete({ignoreNotFound: true});
  }
  return {cancelledReservations: seats.size};
}

/** `.../o/events%2Fuid%2F123.jpg?alt=media&token=…` → `events/uid/123.jpg`. */
export function storagePathFromUrl(url: unknown): string | null {
  if (typeof url !== "string") return null;
  const match = /\/o\/([^?]+)/.exec(url);
  if (!match) return null;
  try {
    return decodeURIComponent(match[1]);
  } catch {
    return null;
  }
}

async function notifyReviewAuthor(
  reviewId: string,
  note: string | null,
): Promise<void> {
  const review = await db.doc(`reviews/${reviewId}`).get();
  if (!review.exists) return;
  await notify(review.get("authorId") as string, {
    type: "reviewHidden",
    title: "Votre avis est masqué",
    body: note ?
      `Motif : ${note}` :
      "Plusieurs personnes l'ont signalé. La modération va le vérifier.",
    eventId: review.get("eventId") as string,
    reservationId: "",
  });
}

// --------------------------------------------------------------------------
// 7b. Administrators
// --------------------------------------------------------------------------

/**
 * Grants or revokes the `admin` claim by email. Admin-only; an admin cannot
 * revoke themselves (so the last admin can never lock the project out). The
 * first admin is created from a terminal: `make grant-admin EMAIL=…`, which
 * runs the same [applyAdminClaim].
 */
export const setAdminRole = onCall(async (request) => {
  const adminUid = requireAdmin(request);
  const {email, admin} = (request.data ?? {}) as {
    email?: unknown;
    admin?: unknown;
  };
  if (typeof email !== "string" || !/^[^@\s]+@[^@\s]+$/.test(email.trim())) {
    throw new HttpsError("invalid-argument", "Adresse email invalide.");
  }
  if (typeof admin !== "boolean") {
    throw new HttpsError("invalid-argument", "Requête invalide.");
  }
  const user = await getAuth()
    .getUserByEmail(email.trim().toLowerCase())
    .catch(() => {
      throw new HttpsError("not-found", "Aucun compte avec cet email.");
    });
  if (!admin && user.uid === adminUid) {
    throw new HttpsError(
      "failed-precondition",
      "Vous ne pouvez pas retirer votre propre rôle d'administrateur.",
    );
  }
  await applyAdminClaim(user.uid, admin, adminUid);
  return {uid: user.uid, email: user.email ?? null, admin};
});

/**
 * Sets or clears the claim (other claims kept), mirrors it in `admins/{uid}`
 * for the in-app list, and records it in the audit trail. The user sees the
 * change after their ID token refreshes (sign out and in, or within an hour).
 */
export async function applyAdminClaim(
  uid: string,
  admin: boolean,
  by: string,
): Promise<void> {
  const auth = getAuth();
  const user = await auth.getUser(uid);
  const claims = {...(user.customClaims ?? {})} as Record<string, unknown>;
  if (admin) claims.admin = true;
  else delete claims.admin;
  await auth.setCustomUserClaims(uid, claims);

  const mirror = db.doc(`admins/${uid}`);
  if (admin) {
    await mirror.set({
      email: user.email ?? null,
      name: user.displayName ?? null,
      grantedBy: by,
      grantedAt: FieldValue.serverTimestamp(),
    });
  } else {
    await mirror.delete();
  }
  await audit(admin ? "admin.granted" : "admin.revoked", {uid, by});
}

function requireSignedIn(request: {
  app?: unknown;
  auth?: {uid: string};
}): string {
  if (ENFORCE_APP_CHECK.value() && !request.app) {
    throw new HttpsError("permission-denied", "Application non vérifiée.");
  }
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Vous devez être connecté.");
  }
  return request.auth.uid;
}

function requireAdmin(request: {
  app?: unknown;
  auth?: {uid: string; token: Record<string, unknown>};
}): string {
  if (ENFORCE_APP_CHECK.value() && !request.app) {
    throw new HttpsError("permission-denied", "Application non vérifiée.");
  }
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Vous devez être connecté.");
  }
  if (request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Réservé à l'administration.");
  }
  return request.auth.uid;
}

// --------------------------------------------------------------------------
// 8. Public event page (F-08)
// --------------------------------------------------------------------------

/**
 * `GET /e/{eventId}` on Firebase Hosting (rewrite in firebase.json).
 *
 * What a link preview crawler and a person without the app both see: title,
 * date, place, organizer, seats left, and Open Graph / Twitter tags so the
 * link unfurls in WhatsApp, Messenger or Slack. On Android the App Links
 * declared in the manifest open the app directly instead; the page is the
 * fallback.
 *
 * The event is read with the Admin SDK: events are not public in the rules,
 * but the fields rendered here are the ones an organizer publishes to be
 * shared. Nothing about attendees is ever rendered.
 */
export const publicEventPage = onRequest(
  {maxInstances: 10},
  async (req, res) => {
    if (req.method !== "GET" && req.method !== "HEAD") {
      res.set("Allow", "GET, HEAD").status(405).send("");
      return;
    }
    const match = /^\/e\/([^/]+)\/?$/.exec(req.path);
    if (!match) {
      res.redirect(302, "/");
      return;
    }
    let eventId: string;
    try {
      eventId = decodeURIComponent(match[1]);
    } catch {
      eventId = "";
    }
    const valid =
      eventId.length > 0 &&
      eventId.length <= 200 &&
      !eventId.includes("/") &&
      eventId !== "." &&
      eventId !== "..";
    const snap = valid ? await db.doc(`events/${eventId}`).get() : undefined;

    if (!snap?.exists) {
      res
        .status(404)
        .set("Cache-Control", "public, max-age=60")
        .type("html")
        .send(renderNotFoundPage());
      return;
    }
    res
      .status(200)
      .set("Cache-Control", "public, max-age=300, s-maxage=600")
      .type("html")
      .send(renderEventPage(eventId, snap.data()!, Date.now()));
  },
);

const CATEGORY_LABELS: Record<string, string> = {
  conference: "Conférence",
  meetup: "Meetup",
  workshop: "Atelier",
  concert: "Concert",
  sport: "Sport",
  culture: "Culture",
  other: "Événement",
};

export function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export function renderEventPage(
  eventId: string,
  data: DocumentData,
  nowMillis: number,
): string {
  const startsAt = (data.startsAt as Timestamp).toDate();
  const day = new Intl.DateTimeFormat("fr-FR", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: TIME_ZONE,
  }).format(startsAt);
  const hour = new Intl.DateTimeFormat("fr-FR", {
    hour: "2-digit",
    minute: "2-digit",
    timeZone: TIME_ZONE,
  }).format(startsAt);

  const capacity = Number(data.capacity) || 0;
  const available = Math.max(0, Number(data.availablePlaces) || 0);
  const past = startsAt.getTime() <= nowMillis;
  const status = past ?
    "Événement passé" :
    available === 0 ?
      "Complet — liste d'attente dans l'application" :
      `${available} place${available > 1 ? "s" : ""} sur ${capacity} encore libre${available > 1 ? "s" : ""}`;

  const url = `${PUBLIC_ORIGIN}/e/${encodeURIComponent(eventId)}`;
  const description = String(data.description ?? "");
  const excerpt =
    description.length > 600 ? `${description.slice(0, 597)}…` : description;
  const summary = `${day} à ${hour} · ${data.location} · ${status}`;
  const image =
    typeof data.imageUrl === "string" && data.imageUrl.startsWith("https://") ?
      data.imageUrl :
      null;
  const intent =
    `intent://${PUBLIC_ORIGIN.replace("https://", "")}/e/` +
    `${encodeURIComponent(eventId)}#Intent;scheme=https;` +
    `package=${ANDROID_PACKAGE};end`;
  const e = escapeHtml;

  return `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${e(data.title)} · EventHub</title>
<meta name="description" content="${e(summary)}">
<link rel="canonical" href="${e(url)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="EventHub">
<meta property="og:locale" content="fr_FR">
<meta property="og:url" content="${e(url)}">
<meta property="og:title" content="${e(data.title)}">
<meta property="og:description" content="${e(summary)}">
${image ? `<meta property="og:image" content="${e(image)}">\n` : ""}<meta name="twitter:card" content="${image ? "summary_large_image" : "summary"}">
<meta name="twitter:title" content="${e(data.title)}">
<meta name="twitter:description" content="${e(summary)}">
<style>${PAGE_CSS}</style>
</head>
<body>
<main>
  <p class="mark">EventHub</p>
  ${image ? `<img class="cover" src="${e(image)}" alt="">` : ""}
  <p class="eyebrow">${e(CATEGORY_LABELS[data.category] ?? "Événement")}</p>
  <h1>${e(data.title)}</h1>
  <dl>
    <div><dt>Date</dt><dd>${e(day)}</dd></div>
    <div><dt>Heure</dt><dd>${e(hour)}</dd></div>
    <div class="wide"><dt>Lieu</dt><dd>${e(data.location)}</dd></div>
    <div class="wide"><dt>Organisé par</dt><dd>${e(data.organizerName)}</dd></div>
  </dl>
  <p class="status${past || available === 0 ? " muted" : ""}">${e(status)}</p>
  <p class="description">${e(excerpt).replace(/\n/g, "<br>")}</p>
  ${past ? "" : `<a class="cta" href="${e(intent)}">Réserver dans l'application</a>`}
  <p class="foot">Entrée gratuite. La réservation se fait dans l'application EventHub, avec un compte.</p>
</main>
</body>
</html>`;
}

function renderNotFoundPage(): string {
  return `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Événement introuvable · EventHub</title>
<style>${PAGE_CSS}</style>
</head>
<body>
<main>
  <p class="mark">EventHub</p>
  <h1>Cet événement n'existe plus.</h1>
  <p class="description">L'organisateur l'a peut-être supprimé, ou le lien a été mal copié. Les événements à venir sont dans l'application.</p>
</main>
</body>
</html>`;
}

/** Same language as the app: hairlines, 6 px radius, one accent. */
const PAGE_CSS = `
:root{color-scheme:light dark;--ink:#14121f;--muted:#5d5a6e;--line:#e6e4ee;--bg:#faf9fc;--accent:#5b4ff5}
@media (prefers-color-scheme:dark){:root{--ink:#f2f1f7;--muted:#a3a0b5;--line:#2c2a3a;--bg:#0f0e17;--accent:#8c83ff}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
main{max-width:640px;margin:0 auto;padding:28px 20px 48px}
.mark{margin:0 0 28px;font-weight:700;letter-spacing:.02em}
.cover{display:block;width:100%;aspect-ratio:16/9;object-fit:cover;border-radius:6px;margin-bottom:24px}
.eyebrow{margin:0;color:var(--accent);font-size:13px;font-weight:600;text-transform:uppercase;letter-spacing:.08em}
h1{margin:6px 0 24px;font-size:clamp(28px,6vw,40px);line-height:1.12;letter-spacing:-.01em}
dl{display:grid;grid-template-columns:1fr 1fr;margin:0;border-top:1px solid var(--line)}
dl div{padding:12px 0;border-bottom:1px solid var(--line)}
dl div:nth-child(odd):not(.wide){padding-right:12px;border-right:1px solid var(--line)}
dl div:nth-child(even):not(.wide){padding-left:12px}
dl .wide{grid-column:1/-1}
dt{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.06em}
dd{margin:2px 0 0;font-weight:600}
.status{margin:20px 0 0;padding-left:12px;border-left:3px solid var(--accent);font-weight:600}
.status.muted{border-color:var(--muted);color:var(--muted)}
.description{margin:24px 0;color:var(--muted);white-space:normal}
.cta{display:block;text-align:center;padding:14px 18px;border-radius:6px;background:var(--accent);color:#fff;font-weight:600;text-decoration:none}
.foot{margin:16px 0 0;color:var(--muted);font-size:13px}
`;

// --------------------------------------------------------------------------
// Helpers
// --------------------------------------------------------------------------

/**
 * Runs [work] inside a transaction at most once per trigger delivery: the
 * trigger's event id is recorded in `audit/fx_{id}` (TTL 7 days) atomically
 * with the work. [work] must do its reads before its writes.
 */
async function once(
  triggerId: string,
  work: (tx: Transaction) => Promise<void>,
): Promise<void> {
  const marker = db.doc(`audit/fx_${triggerId}`);
  await db.runTransaction(async (tx) => {
    if ((await tx.get(marker)).exists) return;
    await work(tx);
    tx.set(marker, {
      kind: "trigger",
      at: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(Date.now() + 7 * DAY),
    });
  });
}

/** Append-only audit trail, closed to clients, kept one year (TTL). */
async function audit(action: string, details: DocumentData): Promise<void> {
  await db.collection("audit").add({
    kind: "event",
    action,
    ...details,
    at: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + 365 * DAY),
  });
}

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
