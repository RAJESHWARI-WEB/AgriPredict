/* main.js — shared behaviour across every page */

document.addEventListener("DOMContentLoaded", () => {
  // Mobile nav toggle
  const toggle = document.querySelector(".nav-toggle");
  const links = document.querySelector(".nav-links");
  if (toggle && links) {
    toggle.addEventListener("click", () => {
      links.classList.toggle("open");
      const expanded = links.classList.contains("open");
      toggle.setAttribute("aria-expanded", expanded);
    });
  }

  // Warn if the Flask API isn't reachable (common first-run issue:
  // people open index.html directly without starting app.py)
  const banner = document.getElementById("api-banner");
  if (banner) {
    checkApiHealth().then((ok) => {
      if (!ok) {
        banner.textContent =
          "Can't reach the prediction server. Start the backend with " +
          "\"python app.py\" in the backend folder, then refresh this page.";
        banner.classList.add("show");
      }
    });
  }
});

/* ---------------- Lookup history (localStorage) ---------------- */
const HISTORY_KEY = "agripredict_history";
const HISTORY_LIMIT = 8;

function saveToHistory(entry) {
  const list = getHistory();
  list.unshift({ ...entry, when: new Date().toISOString() });
  localStorage.setItem(HISTORY_KEY, JSON.stringify(list.slice(0, HISTORY_LIMIT)));
}

function getHistory() {
  try {
    return JSON.parse(localStorage.getItem(HISTORY_KEY)) || [];
  } catch (e) {
    return [];
  }
}

function clearHistory() {
  localStorage.removeItem(HISTORY_KEY);
}

function formatWhen(iso) {
  const d = new Date(iso);
  return d.toLocaleDateString(undefined, { day: "2-digit", month: "short" }) +
    " " + d.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" });
}
