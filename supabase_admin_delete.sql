-- v21.4 선로 삭제는 관리자만 (서버에서도 막기)
-- Supabase › SQL Editor 에 붙여넣고 Run. 경고가 나오면 Run query. 선로·사진 데이터는 그대로예요.
drop policy if exists "tower3d write lines"  on public.tower3d_lines;
drop policy if exists "tower3d insert lines" on public.tower3d_lines;
drop policy if exists "tower3d update lines" on public.tower3d_lines;
drop policy if exists "tower3d delete lines" on public.tower3d_lines;
create policy "tower3d insert lines" on public.tower3d_lines for insert to authenticated
  with check (public.tower3d_is_member());
create policy "tower3d update lines" on public.tower3d_lines for update to authenticated
  using (public.tower3d_is_member()) with check (public.tower3d_is_member());
create policy "tower3d delete lines" on public.tower3d_lines for delete to authenticated
  using (public.tower3d_is_admin());
