-- CliniTrack approved-doctors-only directory - run ONCE in SQL Editor AFTER
-- doctor_verification.sql. Rerunnable.
--
-- Closes the hole a UI-only filter leaves: a crafted client could book a
-- *pending* doctor (or a pending doctor could browse portal patients) by
-- calling the API directly. After this migration both checks require an
-- approved doctor at the database level.
--
-- - appointments_patient_insert: patients may only book approved doctors.
-- - patients_portal_doctor_read: only approved doctors may browse linked
--   (portal) patient rows. Private per-doctor rows are unaffected.
-- - public.is_doctor() is superseded by public.is_verified_doctor() and
--   dropped to avoid two sources of truth.

-- ============ 1. approved-doctor helper ============
create or replace function public.is_verified_doctor(uid uuid)
returns boolean
language sql security definer set search_path = public
as $$ select exists (
  select 1 from public.profiles
  where id = uid and role = 'Doctor' and verification_status = 'approved'
) $$;

-- ============ 2. patients book approved doctors only ============
drop policy if exists "appointments_patient_insert" on public.appointments;
create policy "appointments_patient_insert" on public.appointments
  for insert to authenticated
  with check (
    status = 'requested'
    and patient_id in (select public.my_patient_ids())
    and public.is_verified_doctor(owner_id)
  );

-- ============ 3. only approved doctors browse portal patient rows ============
drop policy if exists "patients_portal_doctor_read" on public.patients;
create policy "patients_portal_doctor_read" on public.patients
  for select to authenticated
  using (user_id is not null and public.is_verified_doctor(auth.uid()));

-- ============ 4. drop the superseded helper ============
drop function if exists public.is_doctor(uuid);
