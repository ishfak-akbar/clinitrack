-- CliniTrack initial schema — run this in Supabase Dashboard > SQL Editor
-- Step 2: DB schema + RLS (per-doctor isolation via owner_id = auth.uid())

-- Required for gen_random_uuid()
create extension if not exists "pgcrypto";

-- Updated_at helper
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- ============ profiles (1 row per auth user) ============
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'Doctor',
  specialty text default 'General Physician',
  license_number text,
  phone text,
  qualifications text,
  experience_years text default '',
  clinic_address text default '',
  bio text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ patients ============
create table if not exists public.patients (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  age int check (age is null or (age >= 0 and age <= 130)),
  gender text check (gender is null or gender in ('Male','Female','Other')),
  contact text,
  blood_group text check (blood_group is null or blood_group in ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  medical_history text default '',
  allergies text[] not null default '{}',
  last_visit_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists patients_owner_idx on public.patients(owner_id);
create index if not exists patients_name_idx on public.patients(owner_id, name);

-- ============ appointments ============
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete cascade,
  patient_name text not null default '',
  date_iso date not null,
  date_label text not null default '',
  time_text text not null default '',
  reason text default '',
  doctor_name text default '',
  status text not null default 'scheduled' check (status in ('scheduled','completed','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists appointments_owner_date_idx on public.appointments(owner_id, date_iso);
create index if not exists appointments_patient_idx on public.appointments(patient_id);

-- ============ prescriptions ============
create table if not exists public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete cascade,
  medicine_name text not null,
  dosage text default '',
  duration_text text default '',
  frequency text default 'Daily',
  notes text default '',
  created_at timestamptz not null default now()
);
create index if not exists prescriptions_owner_idx on public.prescriptions(owner_id);
create index if not exists prescriptions_patient_idx on public.prescriptions(patient_id);

-- ============ medicines (inventory per doctor) ============
create table if not exists public.medicines (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  category text default 'General',
  stock int not null default 0 check (stock >= 0),
  unit text default 'tablets',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, name)
);
create index if not exists medicines_owner_idx on public.medicines(owner_id);

-- ============ medicine_orders (order history) ============
create table if not exists public.medicine_orders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  medicine_id uuid references public.medicines(id) on delete set null,
  medicine_name text not null default '',
  quantity int not null check (quantity > 0),
  created_at timestamptz not null default now()
);
create index if not exists medicine_orders_owner_idx on public.medicine_orders(owner_id);

-- ============ follow_ups ============
create table if not exists public.follow_ups (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete cascade,
  patient_name text not null default '',
  follow_up_date date not null,
  follow_up_time text default '',
  notes text default '',
  is_done boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists follow_ups_owner_date_idx on public.follow_ups(owner_id, follow_up_date);

-- ============ updated_at triggers ============
drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.handle_updated_at();

drop trigger if exists trg_patients_updated on public.patients;
create trigger trg_patients_updated before update on public.patients
  for each row execute function public.handle_updated_at();

drop trigger if exists trg_appointments_updated on public.appointments;
create trigger trg_appointments_updated before update on public.appointments
  for each row execute function public.handle_updated_at();

drop trigger if exists trg_medicines_updated on public.medicines;
create trigger trg_medicines_updated before update on public.medicines
  for each row execute function public.handle_updated_at();

drop trigger if exists trg_follow_ups_updated on public.follow_ups;
create trigger trg_follow_ups_updated before update on public.follow_ups
  for each row execute function public.handle_updated_at();

-- ============ RLS: enable + per-user policies ============
alter table public.profiles enable row level security;
alter table public.patients enable row level security;
alter table public.appointments enable row level security;
alter table public.prescriptions enable row level security;
alter table public.medicines enable row level security;
alter table public.medicine_orders enable row level security;
alter table public.follow_ups enable row level security;

-- profiles: user can only touch own row (id = auth.uid())
drop policy if exists "profiles_owner_all" on public.profiles;
create policy "profiles_owner_all" on public.profiles
  for all to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- generic owner tables: helper pattern repeated per table
drop policy if exists "patients_owner_all" on public.patients;
create policy "patients_owner_all" on public.patients
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "appointments_owner_all" on public.appointments;
create policy "appointments_owner_all" on public.appointments
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "prescriptions_owner_all" on public.prescriptions;
create policy "prescriptions_owner_all" on public.prescriptions
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "medicines_owner_all" on public.medicines;
create policy "medicines_owner_all" on public.medicines
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "medicine_orders_owner_all" on public.medicine_orders;
create policy "medicine_orders_owner_all" on public.medicine_orders
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "follow_ups_owner_all" on public.follow_ups;
create policy "follow_ups_owner_all" on public.follow_ups
  for all to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
