-- Only you can read raw clicks.
drop policy if exists "owner read clicks" on public.click_events;
create policy "owner read clicks"
  on public.click_events for select
  to authenticated
  using (auth.uid() = 'YOUR-USER-UUID-HERE'::uuid);

-- Only you can manage links (insert/update/delete/select-all).
drop policy if exists "owner manage links" on public.links;
create policy "owner manage links"
  on public.links for all
  to authenticated
  using (auth.uid() = 'YOUR-USER-UUID-HERE'::uuid)
  with check (auth.uid() = 'YOUR-USER-UUID-HERE'::uuid);