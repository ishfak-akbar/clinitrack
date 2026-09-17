-- CliniTrack patient portal — run ONCE in SQL Editor AFTER schema.sql (and storage.sql).
-- Part 5: open patient self-registration, role routing, patient-owned reads,
-- appointment requests, and a doctors directory.
--
-- Data model notes (isolation preserved):
-- - Doctor-created rows keep user_id NULL and stay per-doctor (owner policy).
-- - Portal rows (user_id NOT NULL) are owned by the patient themselves and
--   additionally readable by any doctor (needed: a patient can book any doctor).

-- ============ 1. link auth user <-> patient row ============
alter table public.patients
  add column if not exists user_id uuid references auth.users(id) on delete set null;

drop index if exists patients_user_idx;
create unique index patients_user_idx
  on public.patients(user_id) where user_id is not null;

-- ============ 2. appointment "requested" status ============
alter table public.appointments drop constraint if exists appointments_status_check;
alter table public.appointments
  add constraint appointments_status_check
  check (status in ('scheduled', 'completed', 'cancelled', 'requested'));

-- ============ 3. role-aware signup trigger + portal row auto-create ============
create or replace function public.handle_new_user()
returns trigger as $$
declare
  v_role text := coalesce(new.raw_user_meta_data->>'role', 'Doctor');
  v_name text := coalesce(new.raw_user_meta_data->>'full_name', '');
begin
  if v_role not in ('Doctor', 'Patient') then
    v_role := 'Doctor';
  end if;

  insert into public.profiles (id, email, full_name, role)
  values (new.id, new.email, v_name, v_role)
  on conflict (id) do nothing;

  -- Portal patients get their own linked row (owned by themselves).
  -- Name is NOT NULL, so fall back rather than aborting signup.
  if v_role = 'Patient' then
    insert into public.patients (owner_id, user_id, name)
    values (new.id, new.id, coalesce(nullif(v_name, ''), 'New Patient'))
    on conflict do nothing;
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============ 4. helper functions (RLS-safe) ============
create or replace function public.my_patient_ids()
returns setof uuid
language sql security definer set search_path = public
as $$ select id from public.patients where user_id = auth.uid() $$;

create or replace function public.is_doctor(uid uuid)
returns boolean
language sql security definer set search_path = public
as $$ select exists (
  select 1 from public.profiles where id = uid and role = 'Doctor'
) $$;

-- ============ 5. doctors directory (authenticated users may see doctors) ============
drop policy if exists "profiles_doctor_directory" on public.profiles;
create policy "profiles_doctor_directory" on public.profiles
  for select to authenticated
  using (role = 'Doctor');

-- ============ 6. doctors can read portal (linked) patient rows ============
-- Private doctor-created rows (user_id IS NULL) stay per-doctor.
drop policy if exists "patients_portal_doctor_read" on public.patients;
create policy "patients_portal_doctor_read" on public.patients
  for select to authenticated
  using (user_id is not null and public.is_doctor(auth.uid()));

-- ============ 7. portal appointment access ============
-- Patient reads own rows (bookings with any doctor).
drop policy if exists "appointments_patient_read" on public.appointments;
create policy "appointments_patient_read" on public.appointments
  for select to authenticated
  using (patient_id in (select public.my_patient_ids()));

-- Patient books: only "requested", own row, real doctor owner.
drop policy if exists "appointments_patient_insert" on public.appointments;
create policy "appointments_patient_insert" on public.appointments
  for insert to authenticated
  with check (
    status = 'requested'
    and patient_id in (select public.my_patient_ids())
    and public.is_doctor(owner_id)
  );

-- Patient cancels own (new row must stay own and become cancelled).
drop policy if exists "appointments_patient_cancel" on public.appointments;
create policy "appointments_patient_cancel" on public.appointments
  for update to authenticated
  using (patient_id in (select public.my_patient_ids()))
  with check (
    patient_id in (select public.my_patient_ids())
    and status = 'cancelled'
  );

-- ============ 8. portal prescription / follow-up reads ============
drop policy if exists "prescriptions_patient_read" on public.prescriptions;
create policy "prescriptions_patient_read" on public.prescriptions
  for select to authenticated
  using (patient_id in (select public.my_patient_ids()));

drop policy if exists "follow_ups_patient_read" on public.follow_ups;
create policy "follow_ups_patient_read" on public.follow_ups
  for select to authenticated
  using (patient_id in (select public.my_patient_ids()));

-- Patient may mark own reminders done (UI only toggles is_done).
drop policy if exists "follow_ups_patient_update" on public.follow_ups;
create policy "follow_ups_patient_update" on public.follow_ups
  for update to authenticated
  using (patient_id in (select public.my_patient_ids()))
  with check (patient_id in (select public.my_patient_ids()));
