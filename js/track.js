import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";

function getSessionId() {
  let sid = sessionStorage.getItem("sid");
  if (!sid) {
    sid = crypto.randomUUID();
    sessionStorage.setItem("sid", sid);
  }
  return sid;
}

export function trackClick(linkId) {
  const payload = {
    link_id: linkId,
    referrer: document.referrer || null,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || null,
    session_id: getSessionId(),
    user_agent: navigator.userAgent,
  };

  // keepalive lets the request outlive navigation to the target URL.
  fetch(`${SUPABASE_URL}/rest/v1/click_events`, {
    method: "POST",
    keepalive: true,
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify(payload),
  }).catch(() => {
    /* analytics is best-effort; never block the link */
  });
}
