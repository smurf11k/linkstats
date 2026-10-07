[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

# linkstats

A self-hosted Linktree with click analytics. Static frontend on GitHub
Pages, Supabase for storage + auth + RLS, and a private dashboard with
per-link filtering and a weekly email report.

---

## What it does

- **Public linktree** (`index.html`) — a custom-styled page of links,
  optionally grouped into sections, optionally shown as icons.
- **Click tracking** — every click is logged to Supabase before
  navigation, best-effort (never blocks the link).
- **Private dashboard** (`dashboard.html`) — email + password sign-in,
  aggregate stats, per-link filtering, and time-series charts.
- **Weekly email** — a GitHub Actions cron job sends you a summary of
  the last 7 days every Sunday.

---

## Features

- Custom linktree with groups, per-link icons, and either a full-button
  or compact-icon-row layout
- Per-link click counts across four time ranges: today, 7 days, 30 days,
  and 1 year
- Chart filters by link — click a row to see only that link's series
- Row-level security on Supabase so only you can read raw click data
- Optional weekly HTML email via Resend
- Open-source: fork, set your own Supabase project, edit `seed.sql`,
  deploy

---

## Stack

- **Frontend**: HTML + CSS + vanilla JS ES modules, served statically
- **Hosting**: GitHub Pages (or anything that serves static files)
- **Backend**: Supabase (Postgres, RLS, Auth, RPC)
- **Charts**: Chart.js (via jsDelivr)
- **Weekly email**: GitHub Actions + Resend

---

## Repo layout

```
.
├── index.html              linktree
├── dashboard.html          private analytics dashboard
├── css/
│   ├── style.css           linktree styles
│   └── dashboard.css       dashboard styles
├── js/
│   ├── config.js           Supabase URL + anon key + display flags
│   ├── supabase.js         shared Supabase client
│   ├── track.js            click-tracking helper
│   ├── index.js            linktree render logic
│   └── dashboard.js        dashboard render + auth logic
├── sql/
│   ├── schema.sql          tables, RLS, RPCs, grants
│   ├── grants.sql          table-level grants
│   ├── owner.sql           lock raw reads to your user
│   ├── seed.sql            sample links + icons
│   └── reset.sql           wipe links + clicks, keep schema
├── scripts/
│   └── weekly_report.py    weekly email job
└── .github/workflows/
    └── weekly-report.yml   cron for the email
```

---

## Setup

### 1. Create a Supabase project

- Go to [supabase.com](https://supabase.com), create a project.
- Open the SQL Editor and run, in order:
  1. `sql/schema.sql` — tables, policies, RPCs, grants
  2. `sql/grants.sql` — table-level grants for anon/authenticated
  3. `sql/seed.sql` — sample links (edit first to your own accounts)

### 2. Sign in once and lock down raw reads

- Open `dashboard.html` locally or on a deployed URL.
- Use the "First time? Create account" toggle to create your user
  with email + password. (Enable signups temporarily in
  Supabase → Authentication → Providers → Email if needed.)
- Copy your user UUID from Supabase → Authentication → Users.
- Edit `sql/owner.sql`, replace `YOUR-USER-UUID-HERE` with it, run it
  in the SQL Editor.
- Disable signups again in Supabase.

### 3. Configure the frontend

Edit `js/config.js`:

```js
export const SUPABASE_URL = "https://<project>.supabase.co";
export const SUPABASE_ANON_KEY = "eyJ...";

// 'buttons' = full-width link buttons (default)
// 'icons'   = small icon tiles for links with show_as_icon = true
export const LINK_DISPLAY = "buttons";

// When true, links without an icon get their label centered.
// Per-link `center_label` (null/true/false) overrides this.
export const CENTER_LABEL_WHEN_NO_ICON = true;
```

Both the URL and anon key are safe to make public. The anon key is
gated by RLS; only you can read `click_events`.

### 4. Deploy

Push the repo to GitHub. Repo → Settings → Pages → Source: "Deploy
from a branch" → main / root. Your linktree is at
`https://<user>.github.io/<repo>/`.

Then back in Supabase → Authentication → URL Configuration:

- **Site URL**: `https://<user>.github.io/<repo>/`
- **Redirect URLs**:
  - `https://<user>.github.io/<repo>/dashboard.html`
  - `https://<user>.github.io/<repo>/**`
  - plus `http://localhost:8000/**` for local testing

Without these, magic links and password resets will redirect to the
wrong place.

### 5. (Optional) Weekly email

1. Sign up at [resend.com](https://resend.com), get an API key.
2. In your GitHub repo → Settings → Secrets and variables → Actions,
   add:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY` (from Supabase → Project Settings → API)
   - `RESEND_API_KEY`
   - `REPORT_TO` (your email)
   - `REPORT_FROM` (e.g. `onboarding@resend.dev`)
3. Actions → Weekly report → Run workflow. It fires every Sunday
   18:00 UTC once verified.

---

## SQL setup

### Fresh install

1. `schema.sql` — creates tables, RLS policies, RPCs, grants
2. `grants.sql` — table-level grants for anon/authenticated
3. `seed.sql` — sample links (edit to your own accounts first)
4. Sign in once via `dashboard.html`, copy your UUID from
   Authentication → Users.
5. `owner.sql` — replace `YOUR-USER-UUID-HERE` first, then run.

### Reset for testing

- `reset.sql` — wipes links + click_events, keeps everything else.
  Then run `seed.sql` again to re-populate.

### Column reference

| Column         | Type    | Notes                                                           |
| -------------- | ------- | --------------------------------------------------------------- |
| `id`           | text    | primary key; referenced by `click_events.link_id`               |
| `label`        | text    | display name                                                    |
| `url`          | text    | destination                                                     |
| `icon`         | text    | optional image URL; CSS forces it to cream                      |
| `group_name`   | text    | optional heading; `null` = ungrouped                            |
| `show_as_icon` | boolean | in `icons` display mode render as a tile (also requires `icon`) |
| `center_label` | boolean | `null` = auto, `true` = force center, `false` = force left      |
| `active`       | boolean | hide without deleting                                           |
| `sort_order`   | int     | lower = higher up; gaps of 10 leave room to insert              |

### RPCs

- `get_clicks_summary(p_range text)` — per-link totals for a range
  (`today` / `week` / `month` / `year`)
- `get_clicks_timeseries(p_range text, p_link_id text default null)` —
  bucketed time series; pass a link id to filter, `null` for all

---

## Adding links

Either edit the seed and re-run, or insert directly:

```sql
insert into public.links
  (id, label, url, icon, group_name, show_as_icon, center_label, sort_order)
values
  ('mylink', 'My Link', 'https://example.com',
   'https://cdn.simpleicons.org/example', 'Group', false, null, 60);
```

Or use Supabase → Table Editor → `links`.

Icons: [Simple Icons](https://simpleicons.org) covers most brands
(`https://cdn.simpleicons.org/<slug>`). For anything they no longer
ship (LinkedIn, some company logos), pull an SVG from Font Awesome via
jsDelivr:

```
https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6/svgs/brands/<name>.svg
```

The frontend runs every icon through `filter: brightness(0) invert(1)`,
so the source colour doesn't matter — everything renders cream.

---

## Security notes

- **Never commit the `service_role` key.** It bypasses RLS. It should
  live only in GitHub Actions secrets (or your shell, temporarily).
- The **anon key** is public by design; RLS is what protects your data.
- `owner.sql` restricts raw `click_events` reads to your UUID. Even a
  leaked anon key can't read your clicks.
- **Disable signups** in Supabase after creating your user. Otherwise
  anyone can create an account on your project (they still can't read
  your clicks, but it's noise).
- Spam clicks are possible — anyone can POST to `click_events`. For a
  personal project this is fine. Add a Supabase Edge Function with
  Turnstile if it becomes a problem.

---

## Local development

```bash
python3 -m http.server 8000
# or: npx serve .
```

Open `http://localhost:8000/` and `http://localhost:8000/dashboard.html`.

ES modules require serving over HTTP — opening the HTML via `file://`
will fail with CORS errors.
