-- CliniTrack storage — run ONCE in Supabase Dashboard > SQL Editor AFTER schema.sql
-- Step 16: avatars (public read, owner write) + attachments (owner only).

-- ============ buckets ============
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true), ('attachments', 'attachments', false)
on conflict (id) do nothing;

-- ============ profiles.avatar_url (idempotent) ============
alter table public.profiles add column if not exists avatar_url text;

-- ============ avatars: anyone can view, only the owner can write ============
-- Path convention: avatars/{auth.uid()}/avatar.jpg
drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'avatars');

drop policy if exists "avatars_owner_write" on storage.objects;
create policy "avatars_owner_write" on storage.objects
  for all to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============ attachments: owner only (private, open via signed URLs) ============
-- Path convention: attachments/{auth.uid()}/{patient_id}/{filename}
drop policy if exists "attachments_owner_all" on storage.objects;
create policy "attachments_owner_all" on storage.objects
  for all to authenticated
  using (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
