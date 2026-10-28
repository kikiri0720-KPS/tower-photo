-- 철탑 3D 뷰어 + 기별사진 : 로그인 없이 주소만 알면 같이 쓰기
-- Supabase > SQL Editor 에 전부 붙여넣고 Run 한 번. 여러 번 실행해도 괜찮아요.

-- 1) 선로 표 (3D 뷰어)
create table if not exists public.tower3d_lines (
  id text primary key,
  data jsonb not null,
  updated_by text,
  updated_at timestamptz not null default now()
);

-- 2) 기별사진 표
create table if not exists public.tower3d_photos (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

-- 3) 고칠 때마다 수정 시각 갱신 (다른 사람 폰에 바로 반영되게)
create or replace function public.tower3d_touch() returns trigger
language plpgsql as $$ begin new.updated_at = now(); return new; end $$;
drop trigger if exists tower3d_lines_touch on public.tower3d_lines;
create trigger tower3d_lines_touch before update on public.tower3d_lines
  for each row execute function public.tower3d_touch();
drop trigger if exists tower3d_photos_touch on public.tower3d_photos;
create trigger tower3d_photos_touch before update on public.tower3d_photos
  for each row execute function public.tower3d_touch();

-- 4) 로그인 없이 읽기·쓰기 허용
grant select, insert, update, delete on public.tower3d_lines  to anon, authenticated;
grant select, insert, update, delete on public.tower3d_photos to anon, authenticated;
alter table public.tower3d_lines  enable row level security;
alter table public.tower3d_photos enable row level security;
drop policy if exists "tower3d open lines"  on public.tower3d_lines;
create policy "tower3d open lines"  on public.tower3d_lines  for all to anon, authenticated using (true) with check (true);
drop policy if exists "tower3d open photos" on public.tower3d_photos;
create policy "tower3d open photos" on public.tower3d_photos for all to anon, authenticated using (true) with check (true);

-- 5) 사진 보관함 (기존 tower-photos 그대로 사용, 없으면 만듦)
insert into storage.buckets (id, name, public) values ('tower-photos', 'tower-photos', false)
  on conflict (id) do nothing;
drop policy if exists "tower3d open storage" on storage.objects;
create policy "tower3d open storage" on storage.objects for all to anon, authenticated
  using (bucket_id = 'tower-photos') with check (bucket_id = 'tower-photos');
