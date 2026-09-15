/// Names of the Supabase objects the app talks to, in one place.
///
/// Mirrors supabase/migrations: a renamed table or function is a compile
/// error here rather than a runtime 404 in a data source.
abstract final class Tables {
  static const profiles = 'profiles';
  static const notificationPreferences = 'notification_preferences';
  static const devices = 'devices';
  static const administrators = 'administrators';
  static const organizers = 'organizers';
  static const follows = 'follows';
  static const events = 'events';
  static const eventTiers = 'event_tiers';
  static const eventStaff = 'event_staff';
  static const staffInvitations = 'staff_invitations';
  static const reservations = 'reservations';
  static const checkins = 'checkins';
  static const waitlistEntries = 'waitlist_entries';
  static const favorites = 'favorites';
  static const reviews = 'reviews';
  static const reports = 'reports';
  static const moderationQueue = 'moderation_queue';
  static const moderationDecisions = 'moderation_decisions';
  static const notifications = 'notifications';
}

/// Database functions callable by a signed-in user (`client.rpc`).
abstract final class Rpc {
  static const registerDevice = 'register_device';
  static const saveEvent = 'save_event';
  static const deleteEvent = 'delete_event';
  static const reserveSeat = 'reserve_seat';
  static const cancelReservation = 'cancel_reservation';
  static const joinWaitlist = 'join_waitlist';
  static const leaveWaitlist = 'leave_waitlist';
  static const checkInTicket = 'check_in_ticket';
  static const eventAttendance = 'event_attendance';
  static const inviteCoOrganizer = 'invite_co_organizer';
  static const respondToStaffInvite = 'respond_to_staff_invite';
  static const removeCoOrganizer = 'remove_co_organizer';
  static const moderateContent = 'moderate_content';
  static const setAdminRole = 'set_admin_role';
  static const deleteMyAccount = 'delete_my_account';
}

/// Edge Functions callable by a signed-in user (`client.functions.invoke`).
abstract final class EdgeFunctions {
  static const paymentsCheckout = 'payments-checkout';
  static const paymentsCancel = 'payments-cancel';
  static const paymentsRefund = 'payments-refund';
}

abstract final class Buckets {
  static const eventCovers = 'event-covers';
  static const avatars = 'avatars';
}
