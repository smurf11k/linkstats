-- =====================================================================
-- reset.sql
--
-- Wipes all links (and their click_events, via cascade).
-- Does NOT touch: table definitions, RLS policies, RPCs, grants,
-- or the owner policies in owner.sql.
--
-- Use this for testing. Re-run schema.sql afterward to re-seed.
-- =====================================================================

-- click_events has ON DELETE CASCADE from links, so deleting links
-- removes their click history automatically. Truncating the events
-- table directly first is clearer and also resets the identity counter.
truncate table public.click_events restart identity;
delete from public.links;

-- Verify
select
  (select count(*) from public.links)        as links_remaining,
  (select count(*) from public.click_events) as clicks_remaining;