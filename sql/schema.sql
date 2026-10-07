-- =====================================================================
-- schema.sql
--
-- Tables, RLS policies, RPCs, and grants for the linktree.
-- Idempotent: safe to run on a fresh database and safe to re-run.
--
-- Does NOT seed any links. Run seed.sql for that.
--
-- Run order on a fresh project:
--   1. schema.sql   (this file)
--   2. grants.sql
--   3. seed.sql
--   4. Sign in once, copy your UUID, edit owner.sql, run owner.sql
-- =====================================================================

-- ---- Tables ---------------------------------------------------------

create table if not exists public.links (
  id            text primary key,
  label         text not null,
  url           text not null,
  icon          text,
  group_name    text,
  show_as_icon  boolean not null default false,
  center_label  boolean,
  active        boolean not null default true,
  sort_order    int not null default 0,
  created_at    timestamptz not null default now()
);

create table if not exists public.click_events (
  id          bigint generated always as identity primary key,
  link_id     text not null references public.links(id) on delete cascade,
  clicked_at  timestamptz not null default now(),
  referrer    text,
  timezone    text,
  session_id  text,
  user_agent  text
);

create index if not exists click_events_clicked_at_idx
  on public.click_events (clicked_at desc);
create index if not exists click_events_link_id_idx
  on public.click_events (link_id);

-- ---- Upgrade guards -------------------------------------------------
-- For databases created before these columns existed.

alter table public.links
  add column if not exists group_name text;

alter table public.links
  add column if not exists show_as_icon boolean not null default false;

alter table public.links
  add column if not exists center_label boolean;

-- ---- Row-level security ---------------------------------------------

alter table public.links        enable row level security;
alter table public.click_events enable row level security;

drop policy if exists "public read links" on public.links;
create policy "public read links"
  on public.links for select
  to anon, authenticated
  using (active = true);

drop policy if exists "anon insert clicks" on public.click_events;
create policy "anon insert clicks"
  on public.click_events for insert
  to anon, authenticated
  with check (true);

-- ---- RPC: per-link totals -------------------------------------------

create or replace function public.get_clicks_summary(p_range text)
returns table (
  link_id text,
  label   text,
  url     text,
  clicks  bigint
)
language sql
stable
security invoker
set search_path = public
as $$
  with bounds as (
    select case p_range
      when 'today' then date_trunc('day', now())
      when 'week'  then now() - interval '7 days'
      when 'month' then now() - interval '30 days'
      when 'year'  then now() - interval '365 days'
      else now() - interval '7 days'
    end as since
  )
  select l.id, l.label, l.url, count(ce.id)::bigint as clicks
  from public.links l
  cross join bounds b
  left join public.click_events ce
    on ce.link_id = l.id
   and ce.clicked_at >= b.since
  group by l.id, l.label, l.url
  order by clicks desc, l.label asc;
$$;

-- ---- RPC: time series ------------------------------------------------

create or replace function public.get_clicks_timeseries(
  p_range   text,
  p_link_id text default null
)
returns table (
  bucket timestamptz,
  clicks bigint
)
language sql
stable
security invoker
set search_path = public
as $$
  with params as (
    select
      case p_range
        when 'today' then now() - interval '24 hours'
        when 'week'  then now() - interval '7 days'
        when 'month' then now() - interval '30 days'
        when 'year'  then now() - interval '365 days'
        else now() - interval '7 days'
      end as since,
      case p_range
        when 'today' then interval '1 hour'
        when 'week'  then interval '1 day'
        when 'month' then interval '1 day'
        when 'year'  then interval '1 month'
        else interval '1 day'
      end as step,
      case p_range
        when 'today' then 'hour'
        when 'week'  then 'day'
        when 'month' then 'day'
        when 'year'  then 'month'
        else 'day'
      end as unit
  ),
  series as (
    select gs.bucket, p.unit
    from params p
    cross join lateral generate_series(
      date_trunc(p.unit, p.since),
      date_trunc(p.unit, now()),
      p.step
    ) as gs(bucket)
  )
  select
    s.bucket,
    coalesce(count(ce.id), 0)::bigint as clicks
  from series s
  left join public.click_events ce
    on date_trunc(s.unit, ce.clicked_at) = s.bucket
   and (p_link_id is null or ce.link_id = p_link_id)
  group by s.bucket
  order by s.bucket asc;
$$;

drop function if exists public.get_clicks_timeseries(text);

-- ---- RPC grants ------------------------------------------------------

revoke execute on function public.get_clicks_summary(text)          from public;
revoke execute on function public.get_clicks_timeseries(text, text) from public;

grant execute on function public.get_clicks_summary(text)           to authenticated, service_role;
grant execute on function public.get_clicks_timeseries(text, text)  to authenticated, service_role;