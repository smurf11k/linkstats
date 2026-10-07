-- =====================================================================
-- seed.sql
--
-- Sample links + icons. Edit to match your own accounts.
-- Safe to re-run: existing rows are updated (except icon, active, and
-- created_at, which are preserved).
--
-- Run after schema.sql. Use reset.sql first for a clean slate.
-- =====================================================================

-- ---- Links ----------------------------------------------------------

insert into public.links
  (id, label, url, group_name, show_as_icon, center_label, sort_order)
values
  -- Social
  ('github',        'GitHub',         'https://github.com/yourname',                     'Social',  true,  null,  1),
  ('x',             'X',              'https://x.com/yourname',                          'Social',  true,  null,  2),
  ('instagram',     'Instagram',      'https://instagram.com/yourname',                  'Social',  true,  null,  3),
  ('youtube',       'YouTube',        'https://youtube.com/@yourname',                   'Social',  true,  null,  4),
  ('tiktok',        'TikTok',         'https://tiktok.com/@yourname',                    'Social',  true,  null,  5),
  ('twitch',        'Twitch',         'https://twitch.tv/yourname',                      'Social',  true,  null,  6),
  ('discord',       'Discord',        'https://discord.gg/yourserver',                   'Social',  true,  null,  7),
  ('reddit',        'Reddit',         'https://reddit.com/user/yourname',                'Social',  true,  null,  8),
  ('facebook',      'Facebook',       'https://facebook.com/yourname',                   'Social',  true,  null,  9),
  ('threads',       'Threads',        'https://threads.net/@yourname',                   'Social',  true,  null, 10),
  ('bluesky',       'Bluesky',        'https://bsky.app/profile/yourname.bsky.social',   'Social',  true,  null, 11),
  ('mastodon',      'Mastodon',       'https://mastodon.social/@yourname',               'Social',  true,  null, 12),
  ('linkedin',      'LinkedIn',       'https://linkedin.com/in/yourname',                'Social',  true,  null, 13),
  ('telegram',      'Telegram',       'https://t.me/yourname',                           'Social',  true,  null, 14),
  ('whatsapp',      'WhatsApp',       'https://wa.me/yournumber',                        'Social',  true,  null, 15),
  ('snapchat',      'Snapchat',       'https://snapchat.com/add/yourname',               'Social',  true,  null, 16),

  -- Dev
  ('leetcode',      'LeetCode',       'https://leetcode.com/u/yourname',                 'Dev',     false, null, 20),
  ('stackoverflow', 'Stack Overflow', 'https://stackoverflow.com/users/yourid/yourname', 'Dev',     false, null, 21),
  ('devto',         'Dev.to',         'https://dev.to/yourname',                         'Dev',     false, null, 22),
  ('medium',        'Medium',         'https://medium.com/@yourname',                    'Dev',     false, null, 23),
  ('hashnode',      'Hashnode',       'https://yourname.hashnode.dev',                   'Dev',     false, null, 24),
  ('kaggle',        'Kaggle',         'https://kaggle.com/yourname',                     'Dev',     false, null, 25),
  ('npm',           'npm',            'https://npmjs.com/~yourname',                     'Dev',     false, null, 26),

  -- Support
  ('buymeacoffee',  'Buy Me a Coffee','https://buymeacoffee.com/yourname',               'Support', false, null, 30),
  ('patreon',       'Patreon',        'https://patreon.com/yourname',                    'Support', false, null, 31),
  ('kofi',          'Ko-fi',          'https://ko-fi.com/yourname',                      'Support', false, null, 32),

  -- Ungrouped
  ('spotify',       'Spotify',        'https://open.spotify.com/user/yourname',           null,     false, null, 40),
  ('soundcloud',    'SoundCloud',     'https://soundcloud.com/yourname',                  null,     false, null, 41),
  ('pinterest',     'Pinterest',      'https://pinterest.com/yourname',                   null,     false, null, 42),
  ('goodreads',     'Goodreads',      'https://goodreads.com/yourname',                   null,     false, null, 43),
  ('website',       'Website',        'https://yourname.com',                             null,     false, null, 50),
  ('blog',          'Blog',           'https://blog.yourname.com',                        null,     false, null, 51),
  ('email',         'Email',          'mailto:you@yourname.com',                          null,     false, null, 52)
on conflict (id) do update set
  label        = excluded.label,
  url          = excluded.url,
  group_name   = excluded.group_name,
  show_as_icon = excluded.show_as_icon,
  center_label = excluded.center_label,
  sort_order   = excluded.sort_order;

-- ---- Icons ----------------------------------------------------------

update public.links set icon = 'https://cdn.simpleicons.org/github'        where id = 'github';
update public.links set icon = 'https://cdn.simpleicons.org/x'             where id = 'x';
update public.links set icon = 'https://cdn.simpleicons.org/instagram'     where id = 'instagram';
update public.links set icon = 'https://cdn.simpleicons.org/youtube'       where id = 'youtube';
update public.links set icon = 'https://cdn.simpleicons.org/tiktok'        where id = 'tiktok';
update public.links set icon = 'https://cdn.simpleicons.org/twitch'        where id = 'twitch';
update public.links set icon = 'https://cdn.simpleicons.org/discord'       where id = 'discord';
update public.links set icon = 'https://cdn.simpleicons.org/reddit'        where id = 'reddit';
update public.links set icon = 'https://cdn.simpleicons.org/facebook'      where id = 'facebook';
update public.links set icon = 'https://cdn.simpleicons.org/threads'       where id = 'threads';
update public.links set icon = 'https://cdn.simpleicons.org/bluesky'       where id = 'bluesky';
update public.links set icon = 'https://cdn.simpleicons.org/mastodon'      where id = 'mastodon';
update public.links set icon = 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/brands/linkedin-in.svg' where id = 'linkedin';
update public.links set icon = 'https://cdn.simpleicons.org/telegram'      where id = 'telegram';
update public.links set icon = 'https://cdn.simpleicons.org/whatsapp'      where id = 'whatsapp';
update public.links set icon = 'https://cdn.simpleicons.org/snapchat'      where id = 'snapchat';
update public.links set icon = 'https://cdn.simpleicons.org/leetcode'      where id = 'leetcode';
update public.links set icon = 'https://cdn.simpleicons.org/stackoverflow' where id = 'stackoverflow';
update public.links set icon = 'https://cdn.simpleicons.org/devdotto'      where id = 'devto';
update public.links set icon = 'https://cdn.simpleicons.org/medium'        where id = 'medium';
update public.links set icon = 'https://cdn.simpleicons.org/hashnode'      where id = 'hashnode';
update public.links set icon = 'https://cdn.simpleicons.org/kaggle'        where id = 'kaggle';
update public.links set icon = 'https://cdn.simpleicons.org/npm'           where id = 'npm';
update public.links set icon = 'https://cdn.simpleicons.org/buymeacoffee'  where id = 'buymeacoffee';
update public.links set icon = 'https://cdn.simpleicons.org/patreon'       where id = 'patreon';
update public.links set icon = 'https://cdn.simpleicons.org/kofi'          where id = 'kofi';
update public.links set icon = 'https://cdn.simpleicons.org/spotify'       where id = 'spotify';
update public.links set icon = 'https://cdn.simpleicons.org/soundcloud'    where id = 'soundcloud';
update public.links set icon = 'https://cdn.simpleicons.org/pinterest'     where id = 'pinterest';
update public.links set icon = 'https://cdn.simpleicons.org/goodreads'     where id = 'goodreads';
-- website, blog, email intentionally have no icon