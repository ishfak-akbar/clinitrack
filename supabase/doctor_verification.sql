-- CliniTrack doctor verification — run ONCE in SQL Editor AFTER
-- schema.sql + patient_portal.sql (order with storage.sql doesn't matter).
-- Rerunnable, with one caveat: re-running section 2 approves every pending
-- doctor, so treat re-runs as an admin action.
--
-- Model:
-- - profiles.role gains 'Admin'. Public signup can still only mint
--   Doctor/Patient — the trigger clamps anything else to Doctor, so nobody
--   can self-register as admin. Admins are promoted via SQL (section 7).
-- - profiles.verification_status: pending / approved / rejected. Meaningful
--   for doctors only; patients are always 'approved'.
-- - New doctor signups land in 'pending' and are fully blocked in-app until
--   an admin approves. The patient portal is unaffected.
--
-- Bootstrap the first admin (once, in this order):
--   1. Register admin@clinitrack.com in the app (either role) with your
--      chosen password. The trigger creates its profile row as pending.
--   2. Run this file (or just section 7) to promote it to Admin.
-- Until the approval screen (app step 5) exists, approve a doctor with:
--   update public.profiles set verification_status = 'approved',
--     reviewed_at = now() where email = 'doctor@example.com';
-- Reject with a reason with:
--   update public.profiles set verification_status = 'rejected',
--     rejection_reason = 'License number could not be verified.',
--     reviewed_at = now() where email = 'doctor@example.com';

-- ============ 1. credential + verification columns ============
alter table public.profiles
  add column if not exists verification_status text
    not null default 'pending'
    check (verification_status in ('pending', 'approved', 'rejected')),
  add column if not exists chamber_name text default '',
  add column if not exists degree text default '',
  add column if not exists graduating_institution text default '',
  add column if not exists graduation_year int
    check (graduation_year is null or (graduation_year >= 1950 and graduation_year <= 2100)),
  add column if not exists specialties text[] not null default '{}',
  add column if not exists reviewed_by uuid
    references auth.users(id) on delete set null,
  add column if not exists reviewed_at timestamptz,
  add column if not exists rejection_reason text default '';

-- Roles are now a closed set: Doctor, Patient, Admin.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('Doctor', 'Patient', 'Admin'));

-- ============ 2. backfill (grandfathers current users) ============
-- Every existing doctor stays approved so nobody is locked out by this
-- migration. Only touches pending rows, so already-reviewed rows are safe.
update public.profiles
set verification_status = 'approved'
where role = 'Doctor' and verification_status = 'pending';

-- Status is meaningless for patients — keep them all approved.
update public.profiles
set verification_status = 'approved'
where role = 'Patient' and verification_status <> 'approved';

-- ============ 3. signup trigger: doctors start pending, no self-admin ============
create or replace function public.handle_new_user()
returns trigger as $$
declare
  v_role text := coalesce(new.raw_user_meta_data->>'role', 'Doctor');
  v_name text := coalesce(new.raw_user_meta_data->>'full_name', '');
begin
  -- Public signup can only mint Doctor/Patient. Anything else (including a
  -- crafted 'Admin') falls back to Doctor; admins are promoted via SQL.
  if v_role not in ('Doctor', 'Patient') then
    v_role := 'Doctor';
  end if;

  insert into public.profiles (id, email, full_name, role, verification_status)
  values (
    new.id,
    new.email,
    v_name,
    v_role,
    case when v_role = 'Patient' then 'approved' else 'pending' end
  )
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

-- ============ 4. admin helper ============
create or replace function public.is_admin(uid uuid)
returns boolean
language sql security definer set search_path = public
as $$ select exists (
  select 1 from public.profiles where id = uid and role = 'Admin'
) $$;

-- ============ 5. nobody approves themselves (DB-enforced, not just UI) ============
-- Users may edit their own application fields, but role, verification
-- status and review columns are admin-only. Service role / SQL editor
-- (no auth uid) is always allowed so the dashboard keeps working.
create or replace function public.prevent_self_verification()
returns trigger as $$
begin
  if auth.uid() is null then
    return new;
  end if;
  if public.is_admin(auth.uid()) then
    return new;
  end if;
  if new.role is distinct from old.role then
    raise exception 'Only admins can change roles.';
  end if;
  if new.verification_status is distinct from old.verification_status then
    raise exception 'Only admins can change verification status.';
  end if;
  if new.reviewed_by is distinct from old.reviewed_by
     or new.reviewed_at is distinct from old.reviewed_at then
    raise exception 'Only admins can review applications.';
  end if;
  if new.rejection_reason is distinct from old.rejection_reason then
    raise exception 'Only admins can set a rejection reason.';
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trg_profiles_no_self_verify on public.profiles;
create trigger trg_profiles_no_self_verify
  before update on public.profiles
  for each row execute function public.prevent_self_verification();

-- ============ 6. RLS: directory hides pending doctors, admins can review ============
-- Doctors directory: only approved doctors are visible to signed-in users.
drop policy if exists "profiles_doctor_directory" on public.profiles;
create policy "profiles_doctor_directory" on public.profiles
  for select to authenticated
  using (role = 'Doctor' and verification_status = 'approved');

-- Admins can read every profile (the review queue needs this).
drop policy if exists "profiles_admin_read" on public.profiles;
create policy "profiles_admin_read" on public.profiles
  for select to authenticated
  using (public.is_admin(auth.uid()));

-- Admins can update every profile (approve / reject / correct details).
drop policy if exists "profiles_admin_update" on public.profiles;
create policy "profiles_admin_update" on public.profiles
  for update to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- ============ 7. promote the first admin ============
-- Requires the account to exist: register admin@clinitrack.com in the app
-- first (either role), then this flips it. Safe to re-run.
update public.profiles
set role = 'Admin',
    verification_status = 'approved',
    reviewed_at = now()
where email = 'admin@clinitrack.com';
