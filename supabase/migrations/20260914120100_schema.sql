-- =============================================================================
--  EventHub · 2/8 · Schema
--  Tables, constraints and indexes. Invariants that can be declared are
--  declared here (types, CHECK, UNIQUE, foreign keys); the rest lives in
--  triggers (4/8) and RPCs (5/8, 6/8).
-- =============================================================================

-- ============================================================= accounts ===

-- The private profile. Public identity travels denormalised (organizer name
-- on events, participant name on reservations) or through `organizers`.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null
    constraint profiles_name_length check (char_length(btrim(name)) between 2 and 80),
  email extensions.citext not null
    constraint profiles_email_length check (char_length(email::text) between 3 and 320),
  role public.user_role not null,
  bio text
    constraint profiles_bio_length check (bio is null or char_length(bio) <= 500),
  photo_url text
    constraint profiles_photo_url check (
      photo_url is null or (photo_url ~ '^https://' and char_length(photo_url) <= 2048)
    ),
  -- Set by moderation. A suspended account is refused on every request by
  -- `public.api_pre_request` (3/8), without waiting for its token to expire.
  suspended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_email_idx on public.profiles (email);

create table public.notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  event_reminders boolean not null default true,
  booking_alerts boolean not null default true,
  followed_organizers boolean not null default true,
  updated_at timestamptz not null default now()
);

-- Push tokens. A token belongs to one account at a time: signing into another
-- account on the same phone moves it (see public.register_device).
create table public.devices (
  user_id uuid not null references public.profiles (id) on delete cascade,
  device_id text not null
    constraint devices_device_id_length check (char_length(device_id) between 1 and 128),
  token text not null
    constraint devices_token_length check (char_length(token) between 10 and 4096),
  platform public.device_platform not null,
  locale text
    constraint devices_locale_length check (locale is null or char_length(locale) <= 35),
  updated_at timestamptz not null default now(),
  primary key (user_id, device_id)
);

create unique index devices_token_idx on public.devices (token);

-- Back-office access. No client can write here; granted by
-- public.set_admin_role or, for the first administrator, private.grant_admin.
create table public.administrators (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email extensions.citext,
  name text,
  granted_by uuid references auth.users (id) on delete set null,
  granted_at timestamptz not null default now()
);

-- =========================================================== organizers ===

-- The public face of an organizer (F-10): copied from the profile, counters
-- maintained by triggers. Readable by every signed-in user, written by none.
create table public.organizers (
  id uuid primary key references public.profiles (id) on delete cascade,
  name text not null,
  bio text not null default '',
  photo_url text,
  member_since timestamptz not null,
  follower_count integer not null default 0 constraint organizers_followers_positive check (follower_count >= 0),
  event_count integer not null default 0 constraint organizers_events_positive check (event_count >= 0),
  rating_sum integer not null default 0 constraint organizers_rating_sum_positive check (rating_sum >= 0),
  rating_count integer not null default 0 constraint organizers_rating_count_positive check (rating_count >= 0),
  suspended boolean not null default false,
  updated_at timestamptz not null default now()
);

create table public.follows (
  follower_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  organizer_id uuid not null references public.organizers (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, organizer_id),
  constraint follows_not_self check (follower_id <> organizer_id)
);

create index follows_organizer_idx on public.follows (organizer_id);

-- =============================================================== events ===

create table public.events (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles (id) on delete cascade,
  organizer_name text not null
    constraint events_organizer_name_length check (char_length(organizer_name) between 1 and 80),
  title text not null
    constraint events_title_length check (char_length(btrim(title)) between 3 and 120),
  description text not null
    constraint events_description_length check (char_length(btrim(description)) between 1 and 5000),
  category public.event_category not null,
  starts_at timestamptz not null,
  location text not null
    constraint events_location_length check (char_length(btrim(location)) between 1 and 200),
  image_url text
    constraint events_image_url check (
      image_url is null or (image_url ~ '^https://' and char_length(image_url) <= 2048)
    ),
  -- With ticket types, both are the sums of the types (kept by a trigger).
  capacity integer not null
    constraint events_capacity_range check (capacity between 1 and 100000),
  available_places integer not null,
  -- Required as soon as one ticket type is paid.
  currency public.currency_code,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint events_available_bounds check (available_places between 0 and capacity)
);

create index events_catalogue_idx on public.events (starts_at, id);
create index events_organizer_idx on public.events (organizer_id, starts_at);
create index events_category_idx on public.events (category, starts_at);

-- Ticket types (F-12). Prices are integer minor units (cents; ariary for MGA,
-- a zero-decimal currency for Stripe).
create table public.event_tiers (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  name text not null
    constraint event_tiers_name_length check (char_length(btrim(name)) between 1 and 60),
  price integer not null default 0
    constraint event_tiers_price_range check (price between 0 and 100000000),
  capacity integer not null
    constraint event_tiers_capacity_range check (capacity between 1 and 100000),
  available integer not null,
  position smallint not null default 0
    constraint event_tiers_position_range check (position between 0 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint event_tiers_available_bounds check (available between 0 and capacity)
);

create unique index event_tiers_name_idx on public.event_tiers (event_id, lower(btrim(name)));
create index event_tiers_event_idx on public.event_tiers (event_id, position);

-- Co-organizers (F-16), at most 10 per event (enforced by the team RPCs).
create table public.event_staff (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create index event_staff_user_idx on public.event_staff (user_id);

-- Invitations carry a copy of what the invitee needs to decide, because the
-- invitee cannot read the inviter's profile.
create table public.staff_invitations (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  email extensions.citext not null,
  name text not null default '',
  invited_by uuid references public.profiles (id) on delete set null,
  invited_by_name text not null default '',
  event_title text not null,
  event_starts_at timestamptz not null,
  status public.invitation_status not null default 'pending',
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  primary key (event_id, user_id)
);

create index staff_invitations_user_idx on public.staff_invitations (user_id, status);

-- ========================================================= reservations ===

create table public.reservations (
  id uuid primary key default gen_random_uuid(),
  -- History outlives the event and the account: both references become null,
  -- the snapshot columns stay.
  event_id uuid references public.events (id) on delete set null,
  user_id uuid references public.profiles (id) on delete set null,
  organizer_id uuid references public.profiles (id) on delete set null,
  user_name text not null,
  user_email extensions.citext not null,
  event_title text not null,
  event_starts_at timestamptz not null,
  event_location text not null,
  status public.reservation_status not null,
  reserved_at timestamptz not null default now(),
  cancelled_at timestamptz,
  cancelled_by public.cancellation_origin,
  tier_id uuid references public.event_tiers (id) on delete set null,
  tier_name text,
  -- Payments (F-11): written by the payment functions only.
  price_paid integer not null default 0
    constraint reservations_price_paid_positive check (price_paid >= 0),
  amount_due integer
    constraint reservations_amount_due_positive check (amount_due is null or amount_due > 0),
  currency public.currency_code,
  payment_status public.payment_status,
  checkout_session_id text,
  checkout_url text,
  hold_expires_at timestamptz,
  payment_intent_id text,
  refund_id text,
  reminder_sent_at timestamptz,
  updated_at timestamptz not null default now(),
  -- One seat per participant per event — structural, not a race-prone check.
  constraint reservations_one_per_event unique (event_id, user_id),
  constraint reservations_pending_is_held check (
    status <> 'pending' or (payment_status = 'pending' and hold_expires_at is not null)
  ),
  constraint reservations_cancelled_is_dated check (
    status <> 'cancelled' or cancelled_at is not null
  )
);

create index reservations_user_idx on public.reservations (user_id, event_starts_at desc);
create index reservations_event_idx on public.reservations (event_id, status, reserved_at desc);
create index reservations_organizer_idx on public.reservations (organizer_id, reserved_at desc);
create index reservations_reminder_idx on public.reservations (event_starts_at)
  where status = 'confirmed' and reminder_sent_at is null;
create index reservations_holds_idx on public.reservations (hold_expires_at)
  where status = 'pending';

-- Door check-in: an append-only fact.
create table public.checkins (
  reservation_id uuid primary key references public.reservations (id) on delete cascade,
  event_id uuid not null references public.events (id) on delete cascade,
  scanned_by uuid references public.profiles (id) on delete set null,
  scanned_at timestamptz not null default now()
);

create index checkins_event_idx on public.checkins (event_id, scanned_at desc);

create table public.waitlist_entries (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  user_name text not null,
  created_at timestamptz not null default now(),
  notified_at timestamptz,
  primary key (event_id, user_id)
);

create index waitlist_queue_idx on public.waitlist_entries (event_id, created_at);
create index waitlist_user_idx on public.waitlist_entries (user_id);

create table public.favorites (
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  event_id uuid not null references public.events (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

create index favorites_user_idx on public.favorites (user_id, created_at desc);

-- ============================================================== reviews ===

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  -- Denormalised so the organizer's rating can be adjusted even while the
  -- event itself is being deleted.
  organizer_id uuid references public.organizers (id) on delete set null,
  author_id uuid default auth.uid() references public.profiles (id) on delete set null,
  author_name text not null,
  rating smallint not null
    constraint reviews_rating_range check (rating between 1 and 5),
  comment text not null default ''
    constraint reviews_comment_length check (char_length(comment) <= 2000),
  hidden boolean not null default false,
  hidden_at timestamptz,
  moderated_at timestamptz,
  moderated_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  constraint reviews_one_per_author unique (event_id, author_id)
);

create index reviews_event_idx on public.reviews (event_id, created_at desc);
create index reviews_author_idx on public.reviews (author_id);

-- =========================================================== moderation ===

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  target_type public.report_target not null,
  target_id text not null
    constraint reports_target_id_length check (char_length(target_id) between 1 and 200),
  reason public.report_reason not null,
  details text not null default ''
    constraint reports_details_length check (char_length(details) <= 2000),
  reporter_id uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  -- One report per account per target: the automatic threshold counts people.
  constraint reports_one_per_reporter unique (target_type, target_id, reporter_id)
);

create index reports_target_idx on public.reports (target_type, target_id, created_at desc);

create table public.moderation_queue (
  target_type public.report_target not null,
  target_id text not null,
  -- "review_<uuid>": the id the app routes to.
  id text not null unique,
  report_count integer not null default 0,
  last_reason public.report_reason,
  status public.moderation_status not null default 'open',
  auto_hidden boolean not null default false,
  decision public.moderation_action,
  decision_note text,
  decided_by uuid references public.profiles (id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (target_type, target_id)
);

create index moderation_queue_open_idx on public.moderation_queue (status, report_count desc, updated_at desc);

create table public.moderation_decisions (
  id bigint generated always as identity primary key,
  target_type public.report_target not null,
  target_id text not null,
  action public.moderation_action not null,
  note text not null default '',
  decided_by uuid references public.profiles (id) on delete set null,
  decided_at timestamptz not null default now(),
  foreign key (target_type, target_id)
    references public.moderation_queue (target_type, target_id) on delete cascade
);

create index moderation_decisions_target_idx
  on public.moderation_decisions (target_type, target_id, decided_at desc);

-- ======================================================== notifications ===

-- In-app history of every push (30 days).
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type public.notification_type not null,
  title text not null,
  body text not null,
  event_id uuid,
  reservation_id uuid,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  expires_at timestamptz not null default now() + interval '30 days'
);

create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_unread_idx on public.notifications (user_id) where read_at is null;
create index notifications_expiry_idx on public.notifications (expires_at);

-- ============================================================ job queue ===

-- Outbox for side effects that leave the database: push delivery (FCM),
-- Stripe refunds, Storage clean-up. Filled inside the business transaction
-- — so a rolled-back booking never sends a push — and drained by the
-- `worker` Edge Function (7/8).
create table private.jobs (
  id bigint generated always as identity primary key,
  kind text not null
    constraint jobs_kind check (kind in ('push', 'refund', 'storage.delete')),
  payload jsonb not null,
  status text not null default 'queued'
    constraint jobs_status check (status in ('queued', 'running', 'done', 'failed')),
  attempts integer not null default 0,
  run_after timestamptz not null default now(),
  locked_until timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  finished_at timestamptz
);

create index jobs_due_idx on private.jobs (run_after, id) where status in ('queued', 'running');
create index jobs_finished_idx on private.jobs (finished_at) where status in ('done', 'failed');
