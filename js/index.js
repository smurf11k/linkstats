import { supabase } from "./supabase.js";
import { trackClick } from "./track.js";
import { LINK_DISPLAY, CENTER_LABEL_WHEN_NO_ICON } from "./config.js";

const container = document.getElementById("links");

const CHEVRON = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"
  stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9 6l6 6-6 6"/></svg>`;

/* ---- Builders ------------------------------------------------------- */

function buildButton(link, index) {
  const a = document.createElement("a");
  const shouldCenter =
    link.center_label ?? (CENTER_LABEL_WHEN_NO_ICON && !link.icon);
  a.className = "link" + (shouldCenter ? " link--center" : "");
  a.href = link.url;
  a.target = "_blank";
  a.rel = "noopener noreferrer";
  a.dataset.linkId = link.id;
  a.style.setProperty("--i", index);

  if (link.icon) {
    const iconWrap = document.createElement("span");
    iconWrap.className = "link-icon";
    const img = document.createElement("img");
    img.src = link.icon;
    img.alt = "";
    img.loading = "lazy";
    img.decoding = "async";
    img.onerror = () => {
      iconWrap.style.visibility = "hidden";
    };
    iconWrap.appendChild(img);
    a.appendChild(iconWrap);
  }

  const label = document.createElement("span");
  label.className = "link-label";
  label.textContent = link.label;
  a.appendChild(label);

  const arrow = document.createElement("span");
  arrow.className = "link-arrow";
  arrow.innerHTML = CHEVRON;
  a.appendChild(arrow);

  a.addEventListener("click", () => trackClick(link.id));
  return a;
}

function buildIconTile(link, index) {
  const a = document.createElement("a");
  a.className = "icon-tile";
  a.href = link.url;
  a.target = "_blank";
  a.rel = "noopener noreferrer";
  a.dataset.linkId = link.id;
  a.setAttribute("aria-label", link.label);
  a.title = link.label;
  a.style.setProperty("--i", index);

  const img = document.createElement("img");
  img.src = link.icon;
  img.alt = "";
  img.loading = "lazy";
  img.decoding = "async";
  a.appendChild(img);

  a.addEventListener("click", () => trackClick(link.id));
  return a;
}

/* ---- Grouping ------------------------------------------------------- */

function groupLinks(links) {
  // Preserves sort_order within groups; ungrouped links come last.
  const groups = new Map(); // group_name -> link[]
  const ungrouped = [];

  for (const link of links) {
    if (link.group_name) {
      if (!groups.has(link.group_name)) groups.set(link.group_name, []);
      groups.get(link.group_name).push(link);
    } else {
      ungrouped.push(link);
    }
  }
  return { groups, ungrouped };
}

function buildGroup(label, links) {
  const wrap = document.createElement("section");
  wrap.className = "link-group";

  if (label) {
    const heading = document.createElement("h2");
    heading.className = "group-heading";
    heading.textContent = label;
    wrap.appendChild(heading);
  }

  const list = document.createElement("div");
  list.className = "links";
  list.replaceChildren(...links.map(buildButton));
  wrap.appendChild(list);

  return wrap;
}

/* ---- Render --------------------------------------------------------- */

async function load() {
  const { data, error } = await supabase
    .from("links")
    .select(
      "id, label, url, icon, group_name, show_as_icon, center_label, sort_order",
    )
    .eq("active", true)
    .order("sort_order", { ascending: true });

  if (error) {
    console.error(error);
    container.textContent = "Could not load links.";
    return;
  }

  const links = data || [];

  if (LINK_DISPLAY === "icons") {
    renderIconMode(links);
  } else {
    renderButtonMode(links);
  }
}

function renderIconMode(links) {
  const asTiles = links.filter((l) => l.show_as_icon && l.icon);
  const asTilesIds = new Set(asTiles.map((l) => l.id));
  const asButtons = links.filter((l) => !asTilesIds.has(l.id));

  const nodes = [];

  if (asTiles.length) {
    const row = document.createElement("nav");
    row.className = "icon-row";
    row.setAttribute("aria-label", "Social links");
    row.replaceChildren(...asTiles.map(buildIconTile));
    nodes.push(row);
  }

  if (asButtons.length) {
    const { groups, ungrouped } = groupLinks(asButtons);

    for (const [name, groupLinks] of groups) {
      nodes.push(buildGroup(name, groupLinks));
    }

    if (ungrouped.length) {
      const label = groups.size > 0 ? "More" : null;
      nodes.push(buildGroup(label, ungrouped));
    }
  }

  container.replaceChildren(...nodes);
}

function renderButtonMode(links) {
  const { groups, ungrouped } = groupLinks(links);
  const nodes = [];

  for (const [name, groupLinks] of groups) {
    nodes.push(buildGroup(name, groupLinks));
  }
  if (ungrouped.length) {
    const label = groups.size > 0 ? "More" : null;
    nodes.push(buildGroup(label, ungrouped));
  }

  container.replaceChildren(...nodes);
}

load();
