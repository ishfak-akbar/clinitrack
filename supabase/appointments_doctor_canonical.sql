-- CliniTrack: owner_id is the canonical doctor reference for appointments.
-- Run ONCE in SQL Editor AFTER schema.sql + patient_portal.sql. Rerunnable.
--
-- Why: `doctor_name` is a display snapshot only (offline lists, emails).
-- Matching "same doctor?" must use `owner_id` — names drift when a doctor
-- edits their profile. Clients already do this; this migration repairs old
-- rows and guarantees future rows carry a name even if the client sends ''.
--
-- Covered by existing `appointments_owner_date_idx(owner_id, date_iso)`,
-- so no new index is needed.

-- ============ 1. backfill empty snapshots from the doctor's profile ============
update public.appointments as a
set doctor_name = p.full_name
from public.profiles as p
where a.owner_id = p.id
  and (a.doctor_name is null or a.doctor_name = '')
  and p.full_name is not null
  and p.full_name <> '';

-- ============ 2. auto-fill doctor_name on future inserts ============
create or replace function public.fill_appointment_doctor_name()
returns trigger as $$
begin
  if (new.doctor_name is null or new.doctor_name = '')
     and new.owner_id is not null then
    select p.full_name into new.doctor_name
    from public.profiles as p
    where p.id = new.owner_id;
    if new.doctor_name is null then
      new.doctor_name := '';
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trg_appointments_doctor_name on public.appointments;
create trigger trg_appointments_doctor_name
  before insert on public.appointments
  for each row execute function public.fill_appointment_doctor_name();
