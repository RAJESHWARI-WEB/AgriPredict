/*
 * api.js
 * Tiny fetch wrapper around the Flask backend.
 * Change API_BASE_URL if the backend runs somewhere other than localhost
 * (e.g. when it's deployed on Render/Railway/PythonAnywhere).
 */

const API_BASE_URL = (function () {
  // When the web page is served BY the Flask app itself (python app.py),
  // relative paths work automatically. When opened straight from the
  // filesystem or a separate static host, fall back to localhost:5000.
  if (window.location.protocol === "file:") {
    return "http://127.0.0.1:5000";
  }
  return ""; // same-origin
})();

async function apiPost(path, payload) {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  let data;
  try {
    data = await res.json();
  } catch (e) {
    throw new Error("The server sent back something that wasn't valid JSON.");
  }

  if (!res.ok) {
    throw new Error(data.error || `Request failed (${res.status})`);
  }
  return data;
}

async function apiGet(path) {
  const res = await fetch(`${API_BASE_URL}${path}`);
  if (!res.ok) throw new Error(`Request failed (${res.status})`);
  return res.json();
}

async function checkApiHealth() {
  try {
    await apiGet("/api/health");
    return true;
  } catch (e) {
    return false;
  }
}
