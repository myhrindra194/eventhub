-- Run in the Supabase SQL editor for the bucket configured in .env.
-- The Flutter client authenticates with Firebase, so Supabase receives these
-- storage requests as anon unless Supabase third-party JWT auth is configured.

create policy "event images insert"
on storage.objects
for insert
to anon, authenticated
with check (
  bucket_id = 'eventhub-images'
  and name like 'events/%'
);

create policy "event images update"
on storage.objects
for update
to anon, authenticated
using (
  bucket_id = 'eventhub-images'
  and name like 'events/%'
)
with check (
  bucket_id = 'eventhub-images'
  and name like 'events/%'
);

create policy "event images select"
on storage.objects
for select
to anon, authenticated
using (
  bucket_id = 'eventhub-images'
  and name like 'events/%'
);