import { supabase } from "./supabase.js";

const authSection = document.getElementById("auth");
const panel = document.getElementById("panel");
const authForm = document.getElementById("auth-form");
const authMsg = document.getElementById("auth-msg");
const authTitle = document.getElementById("auth-title");
const emailEl = document.getElementById("email");
const passwordEl = document.getElementById("password");
const submitBtn = document.getElementById("submit-btn");
const modeToggle = document.getElementById("mode-toggle");
const signout = document.getElementById("signout");
const rangeFilters = document.querySelectorAll(".filter[data-range]");
const chartTitle = document.getElementById("chart-title");
const totalEl = document.getElementById("total");
const topEl = document.getElementById("top");
const tbody = document.querySelector("#table tbody");

let chart = null;
let currentRange = "week";
let currentLinkId = ""; // '' means all
let mode = "signin";

/* ---- Auth ----------------------------------------------------------- */

modeToggle.addEventListener("click", () => {
  mode = mode === "signin" ? "signup" : "signin";
  updateModeUI();
});

function updateModeUI() {
  if (mode === "signin") {
    authTitle.textContent = "Sign in";
    submitBtn.textContent = "Unlock";
    passwordEl.setAttribute("autocomplete", "current-password");
    modeToggle.textContent = "First time? Create account";
  } else {
    authTitle.textContent = "Create account";
    submitBtn.textContent = "Create";
    passwordEl.setAttribute("autocomplete", "new-password");
    modeToggle.textContent = "Already have an account? Sign in";
  }
  authMsg.textContent = "";
}

authForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  authMsg.textContent = "";

  const email = emailEl.value.trim();
  const password = passwordEl.value;

  if (mode === "signin") {
    authMsg.textContent = "Unlocking…";
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) {
      authMsg.textContent = "Wrong email or password.";
      passwordEl.value = "";
      passwordEl.focus();
    }
    return;
  }

  authMsg.textContent = "Creating…";
  const { data, error } = await supabase.auth.signUp({ email, password });
  if (error) {
    authMsg.textContent = error.message;
    return;
  }
  if (!data.session)
    authMsg.textContent = "Check your email to confirm, then sign in.";
});

signout.addEventListener("click", async () => {
  await supabase.auth.signOut();
  location.reload();
});

/* ---- Range filters -------------------------------------------------- */

rangeFilters.forEach((btn) => {
  btn.addEventListener("click", () => {
    rangeFilters.forEach((b) => b.classList.toggle("active", b === btn));
    currentRange = btn.dataset.range;
    loadStats();
  });
});

/* ---- Boot ----------------------------------------------------------- */

async function init() {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (session) {
    showPanel();
    loadStats();
  } else {
    showAuth();
  }

  supabase.auth.onAuthStateChange((_event, session) => {
    if (session) {
      showPanel();
      loadStats();
    } else {
      showAuth();
    }
  });
}

function showAuth() {
  authSection.classList.remove("hidden");
  panel.classList.add("hidden");
  emailEl.focus();
}

function showPanel() {
  authSection.classList.add("hidden");
  panel.classList.remove("hidden");
}

/* ---- Data ----------------------------------------------------------- */

async function loadStats() {
  const [summaryRes, seriesRes] = await Promise.all([
    supabase.rpc("get_clicks_summary", { p_range: currentRange }),
    supabase.rpc("get_clicks_timeseries", {
      p_range: currentRange,
      p_link_id: currentLinkId || null,
    }),
  ]);

  if (summaryRes.error) return console.error(summaryRes.error);
  if (seriesRes.error) return console.error(seriesRes.error);

  const summary = summaryRes.data || [];
  const series = seriesRes.data || [];

  // Stats cards
  const total = summary.reduce((acc, r) => acc + Number(r.clicks), 0);
  totalEl.textContent = total.toLocaleString();
  topEl.textContent = summary[0]?.clicks > 0 ? summary[0].label : "—";

  // Table — rows are the filters
  tbody.replaceChildren(
    ...summary.map((r) => {
      const tr = document.createElement("tr");
      tr.className = "row" + (currentLinkId === r.link_id ? " row-active" : "");
      tr.dataset.linkId = r.link_id;
      tr.setAttribute("role", "button");
      tr.setAttribute("tabindex", "0");
      tr.setAttribute(
        "aria-pressed",
        currentLinkId === r.link_id ? "true" : "false",
      );

      const toggle = () => {
        currentLinkId = currentLinkId === r.link_id ? "" : r.link_id;
        loadStats();
      };
      tr.addEventListener("click", toggle);
      tr.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          toggle();
        }
      });

      const td1 = document.createElement("td");
      const td2 = document.createElement("td");
      td2.className = "num";
      td1.textContent = r.label;
      td2.textContent = Number(r.clicks).toLocaleString();
      tr.append(td1, td2);
      return tr;
    }),
  );

  // Chart title
  const active = summary.find((r) => r.link_id === currentLinkId);
  chartTitle.textContent = active
    ? `Clicks over time — ${active.label}`
    : "Clicks over time";

  renderChart(series);
}

function renderChart(series) {
  const ctx = document.getElementById("chart");
  const labels = series.map((p) => formatBucket(p.bucket, currentRange));
  const values = series.map((p) => Number(p.clicks));

  if (chart) chart.destroy();

  chart = new Chart(ctx, {
    type: "line",
    data: {
      labels,
      datasets: [
        {
          label: "Clicks",
          data: values,
          tension: 0.25,
          fill: true,
          borderColor: "#c1121f",
          borderWidth: 3,
          backgroundColor: "rgba(193, 18, 31, 0.12)",
          pointBackgroundColor: "#f0ead6",
          pointBorderColor: "#090909",
          pointBorderWidth: 2,
          pointRadius: 4,
          pointHoverRadius: 6,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: "#131313",
          borderColor: "#f0ead6",
          borderWidth: 2,
          titleColor: "#f0ead6",
          bodyColor: "#f0ead6",
          titleFont: { family: "Space Grotesk", weight: "700" },
          bodyFont: { family: "Space Grotesk" },
          padding: 12,
          cornerRadius: 0,
          displayColors: false,
        },
      },
      scales: {
        x: {
          ticks: {
            color: "#7a746a",
            font: { family: "Space Grotesk", size: 11 },
          },
          grid: { color: "#1e1e1e", drawBorder: false },
        },
        y: {
          beginAtZero: true,
          ticks: {
            precision: 0,
            color: "#7a746a",
            font: { family: "Space Grotesk", size: 11 },
          },
          grid: { color: "#1e1e1e", drawBorder: false },
        },
      },
    },
  });
}

function formatBucket(iso, range) {
  const d = new Date(iso);
  if (range === "today")
    return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  if (range === "year")
    return d.toLocaleDateString([], { month: "short", year: "2-digit" });
  return d.toLocaleDateString([], { month: "short", day: "numeric" });
}

init();
