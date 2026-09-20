-- CliniTrack full reset — run in Supabase Dashboard > SQL Editor to start afresh.
-- Empties all app data + storage objects. Does NOT delete auth.users.
-- To also remove users, do Dashboard > Authentication > Users > delete manually.
--
-- Order: children first (CASCADE handles FKs anyway).

-- 1. App data (children -> parents)
truncate table public.follow_ups,
                 public.prescriptions,
                 public.medicine_orders,
                 public.appointments,
                 public.medicines,
                 public.patients
  restart identity cascade;

-- 2. Profiles (keeps auth.users, just clears profile rows so signup trigger recreates)
-- Comment out if you want to keep doctor/patient profiles.
delete from public.profiles;

-- 3. Storage files (avatars + attachments)
-- NOTE: storage.objects is protected — direct SQL DELETE is blocked by
-- storage.protect_delete(). Delete via Dashboard instead:
--   Storage > avatars > select all > Delete, then same for attachments.
-- Or via API with a service_role key (never the anon key).
