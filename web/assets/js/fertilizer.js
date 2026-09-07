/* fertilizer.js — logic for the Fertilizer Advisor page */

const SAMPLES = {
  maize: { soil_type: "Sandy", crop_type: "Maize", temperature: 26, humidity: 52, moisture: 38, nitrogen: 37, potassium: 0, phosphorous: 0 },
  sugarcane: { soil_type: "Loamy", crop_type: "Sugarcane", temperature: 29, humidity: 52, moisture: 45, nitrogen: 12, potassium: 0, phosphorous: 36 },
  cotton: { soil_type: "Black", crop_type: "Cotton", temperature: 34, humidity: 65, moisture: 62, nitrogen: 7, potassium: 9, phosphorous: 30 },
};

const form = document.getElementById("fert-form");
const submitBtn = document.getElementById("submit-btn");
const loading = document.getElementById("loading");
const errorMsg = document.getElementById("error-msg");
const resultArea = document.getElementById("result-area");
const soilSelect = document.getElementById("soil_type");
const cropSelect = document.getElementById("crop_type");

// Populate dropdowns from the backend's /api/meta so the valid options
// always match whatever the model was actually trained on.
(async function populateDropdowns() {
  try {
    const meta = await apiGet("/api/meta");
    fillSelect(soilSelect, meta.soil_types);
    fillSelect(cropSelect, meta.crop_types);
  } catch (e) {
    // Fallback list, only used if the API is unreachable at page load.
    fillSelect(soilSelect, ["Black", "Clayey", "Loamy", "Red", "Sandy"]);
    fillSelect(cropSelect, ["Barley", "Cotton", "Ground Nuts", "Maize", "Millets", "Oil seeds", "Paddy", "Pulses", "Sugarcane", "Tobacco", "Wheat"]);
  }
})();

function fillSelect(select, options) {
  options.forEach((opt) => {
    const el = document.createElement("option");
    el.value = opt;
    el.textContent = opt;
    select.appendChild(el);
  });
}

document.querySelectorAll(".chip[data-sample]").forEach((btn) => {
  btn.addEventListener("click", () => {
    const sample = SAMPLES[btn.dataset.sample];
    Object.entries(sample).forEach(([key, val]) => {
      const input = form.elements[key];
      if (input) input.value = val;
    });
  });
});

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  errorMsg.classList.remove("show");

  const fields = ["soil_type", "crop_type", "temperature", "humidity", "moisture", "nitrogen", "potassium", "phosphorous"];
  const payload = {};
  for (const f of fields) {
    const input = form.elements[f];
    if (input.value === "") {
      showError("Please fill in every field before submitting.");
      return;
    }
    payload[f] = input.value;
  }

  setLoading(true);
  try {
    const data = await apiPost("/api/predict/fertilizer", payload);
    renderResult(data);
    saveToHistory({ type: "fertilizer", label: data.recommended_fertilizer, confidence: data.confidence });
    renderHistory();
  } catch (err) {
    showError(err.message || "Something went wrong talking to the server.");
  } finally {
    setLoading(false);
  }
});

function setLoading(isLoading) {
  loading.classList.toggle("show", isLoading);
  submitBtn.disabled = isLoading;
}

function showError(msg) {
  errorMsg.textContent = msg;
  errorMsg.classList.add("show");
  resultArea.classList.remove("show");
}

function renderResult(data) {
  document.getElementById("result-fert").textContent = data.recommended_fertilizer;
  document.getElementById("result-confidence").textContent = `${data.confidence}% confidence`;
  document.getElementById("result-note").textContent = data.info.note || "";
  document.getElementById("result-npk").textContent = data.info.npk || "—";

  const tbody = document.getElementById("matches-body");
  tbody.innerHTML = "";
  data.top_matches.forEach((m) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${m.fertilizer}</td>
      <td>${m.confidence}%</td>
      <td style="min-width:120px;"><div class="bar-track"><div class="bar-fill" style="width:${m.confidence}%;"></div></div></td>
    `;
    tbody.appendChild(tr);
  });

  resultArea.classList.add("show");
  resultArea.scrollIntoView({ behavior: "smooth", block: "nearest" });
}

function renderHistory() {
  const list = document.getElementById("history-list");
  const items = getHistory().filter((h) => h.type === "fertilizer");
  if (items.length === 0) {
    list.innerHTML = '<li class="history-empty">No lookups yet this session.</li>';
    return;
  }
  list.innerHTML = items
    .map((h) => `<li><span>${h.label}</span><span>${h.confidence}% · ${formatWhen(h.when)}</span></li>`)
    .join("");
}

renderHistory();
