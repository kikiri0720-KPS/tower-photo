-- 철탑 3D + 기별사진 v21: 회원가입(아이디) · 관리자 승인 · 비회원은 보기만
-- Supabase > SQL Editor 에 전부 붙여넣고 Run 한 번. 여러 번 실행해도 괜찮아요.
-- (예전 supabase_open.sql 은 다시 실행하지 마세요 — 다시 누구나 고칠 수 있게 열려요)

-- 1) 회원 표
create table if not exists public.tower3d_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  login text unique not null,
  name text not null default '',
  approved boolean not null default false,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.tower3d_members enable row level security;
grant select on public.tower3d_members to authenticated;

create or replace function public.tower3d_is_member() returns boolean
language sql stable security definer set search_path = public as
$$ select exists(select 1 from public.tower3d_members where user_id = auth.uid() and approved) $$;

create or replace function public.tower3d_is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists(select 1 from public.tower3d_members where user_id = auth.uid() and approved and is_admin) $$;

drop policy if exists "tower3d members read" on public.tower3d_members;
create policy "tower3d members read" on public.tower3d_members for select to authenticated
  using (user_id = auth.uid() or public.tower3d_is_admin());

-- 2) 가입 신청 (맨 처음 가입한 사람은 자동으로 관리자·승인)
create or replace function public.tower3d_register(p_login text, p_name text) returns public.tower3d_members
language plpgsql security definer set search_path = public as $$
declare r public.tower3d_members; first boolean;
begin
  if auth.uid() is null then raise exception '로그인이 필요해요'; end if;
  select not exists(select 1 from public.tower3d_members where is_admin) into first;
  insert into public.tower3d_members(user_id, login, name, approved, is_admin)
    values (auth.uid(), lower(p_login), coalesce(p_name, ''), first, first)
    on conflict (user_id) do update set name = case when excluded.name <> '' then excluded.name else tower3d_members.name end
    returning * into r;
  return r;
end $$;
grant execute on function public.tower3d_register(text, text) to authenticated;

-- 3) 관리자: 승인·승인 취소·관리자 지정
create or replace function public.tower3d_set_member(p_uid uuid, p_approved boolean, p_admin boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.tower3d_is_admin() then raise exception '관리자만 할 수 있어요'; end if;
  if p_uid = auth.uid() and (not p_admin or not p_approved) then raise exception '내 관리자 권한은 스스로 뺄 수 없어요'; end if;
  update public.tower3d_members set approved = p_approved, is_admin = (p_admin and p_approved) where user_id = p_uid;
end $$;
grant execute on function public.tower3d_set_member(uuid, boolean, boolean) to authenticated;

-- 4) 선로·사진 표: 보기는 누구나, 고치기는 승인된 회원만
drop policy if exists "tower3d open lines"  on public.tower3d_lines;
drop policy if exists "tower3d open photos" on public.tower3d_photos;
revoke insert, update, delete on public.tower3d_lines  from anon;
revoke insert, update, delete on public.tower3d_photos from anon;
grant select on public.tower3d_lines  to anon, authenticated;
grant select on public.tower3d_photos to anon, authenticated;
grant insert, update, delete on public.tower3d_lines  to authenticated;
grant insert, update, delete on public.tower3d_photos to authenticated;

drop policy if exists "tower3d read lines"   on public.tower3d_lines;
drop policy if exists "tower3d write lines"  on public.tower3d_lines;
drop policy if exists "tower3d read photos"  on public.tower3d_photos;
drop policy if exists "tower3d write photos" on public.tower3d_photos;
create policy "tower3d read lines"   on public.tower3d_lines  for select to anon, authenticated using (true);
create policy "tower3d write lines"  on public.tower3d_lines  for all to authenticated
  using (public.tower3d_is_member()) with check (public.tower3d_is_member());
create policy "tower3d read photos"  on public.tower3d_photos for select to anon, authenticated using (true);
create policy "tower3d write photos" on public.tower3d_photos for all to authenticated
  using (public.tower3d_is_member()) with check (public.tower3d_is_member());

-- 5) 사진 보관함: 보기는 누구나, 올리기·지우기는 승인된 회원만
drop policy if exists "tower3d open storage"   on storage.objects;
drop policy if exists "tower3d read storage"   on storage.objects;
drop policy if exists "tower3d insert storage" on storage.objects;
drop policy if exists "tower3d update storage" on storage.objects;
drop policy if exists "tower3d delete storage" on storage.objects;
create policy "tower3d read storage"   on storage.objects for select to anon, authenticated using (bucket_id = 'tower-photos');
create policy "tower3d insert storage" on storage.objects for insert to authenticated
  with check (bucket_id = 'tower-photos' and public.tower3d_is_member());
create policy "tower3d update storage" on storage.objects for update to authenticated
  using (bucket_id = 'tower-photos' and public.tower3d_is_member()) with check (bucket_id = 'tower-photos' and public.tower3d_is_member());
create policy "tower3d delete storage" on storage.objects for delete to authenticated
  using (bucket_id = 'tower-photos' and public.tower3d_is_member());
