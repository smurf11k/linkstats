import json
import os
import urllib.request
from datetime import datetime, timezone

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SERVICE_KEY  = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
RESEND_KEY   = os.environ["RESEND_API_KEY"]
REPORT_TO    = os.environ["REPORT_TO"]
REPORT_FROM  = os.environ.get("REPORT_FROM", "onboarding@resend.dev")


def fetch_summary():
    body = json.dumps({"p_range": "week"}).encode()
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/rpc/get_clicks_summary",
        data=body,
        method="POST",
        headers={
            "apikey": SERVICE_KEY,
            "Authorization": f"Bearer {SERVICE_KEY}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode())


def build_html(rows):
    total = sum(int(r["clicks"]) for r in rows)
    lines = "".join(
        f"<tr>"
        f"<td style='padding:8px 0;border-bottom:1px solid #eee'>{r['label']}</td>"
        f"<td style='padding:8px 0;border-bottom:1px solid #eee;text-align:right'>{r['clicks']}</td>"
        f"</tr>"
        for r in rows
    )
    today = datetime.now(timezone.utc).strftime("%b %d, %Y")
    return f"""
    <div style="font-family:system-ui,-apple-system,sans-serif;max-width:520px;
                margin:0 auto;color:#111">
      <h2 style="margin:0 0 4px">Your weekly link report</h2>
      <p style="color:#666;margin:0 0 24px">{today}</p>
      <p style="font-size:32px;font-weight:700;margin:0 0 24px">{total} clicks</p>
      <table style="width:100%;border-collapse:collapse">
        <thead><tr>
          <th style="text-align:left;color:#666;font-weight:500;padding-bottom:8px">Link</th>
          <th style="text-align:right;color:#666;font-weight:500;padding-bottom:8px">Clicks</th>
        </tr></thead>
        <tbody>{lines}</tbody>
      </table>
      <p style="color:#888;font-size:12px;margin-top:24px">Sent by your linktree.</p>
    </div>
    """


def send_email(html):
    subject = f"Weekly link report — {datetime.now(timezone.utc).strftime('%b %d')}"
    body = json.dumps({
        "from": REPORT_FROM,
        "to": [REPORT_TO],
        "subject": subject,
        "html": html,
    }).encode()
    req = urllib.request.Request(
        "https://api.resend.com/emails",
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {RESEND_KEY}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req) as r:
        print(r.status, r.read().decode())


def main():
    rows = fetch_summary()
    send_email(build_html(rows))


if __name__ == "__main__":
    main()