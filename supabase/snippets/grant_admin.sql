-- =============================================================================
--  First administrator — run once in Supabase → SQL Editor.
-- =============================================================================
--  The account must already exist (signed up in the app). The function is
--  executable by no API role: only a trusted connection like this one can
--  create the first administrator. Later ones are granted from the app
--  (Profil → Modération → Administrateurs), which calls set_admin_role.
--
--  The person signs out and in again (or waits for the next token refresh)
--  to see the Modération entry.

select private.grant_admin('moderation@exemple.org');

-- Revoke:
-- select private.grant_admin('moderation@exemple.org', false);
