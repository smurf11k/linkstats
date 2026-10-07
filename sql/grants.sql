-- One-time grants for the anon and authenticated roles.
-- Run once per project, after schema.sql.

grant usage on schema public to anon, authenticated;

grant select on public.links to anon, authenticated;

grant insert on public.click_events to anon, authenticated;
grant select on public.click_events to authenticated;

grant execute on function public.get_clicks_summary(text)    to authenticated, service_role;
grant execute on function public.get_clicks_timeseries(text) to authenticated, service_role;


-- RPCs: lock execution to authenticated + service_role only.

revoke execute on function public.get_clicks_summary(text)    from public;
revoke execute on function public.get_clicks_timeseries(text) from public;

grant execute on function public.get_clicks_summary(text)    to authenticated, service_role;
grant execute on function public.get_clicks_timeseries(text) to authenticated, service_role;