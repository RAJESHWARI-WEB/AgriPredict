/* crop.js — logic for the Crop Advisor page */

const SAMPLES = {
  rice: { N: 90, P: 42, K: 43, temperature: 20.9, humidity: 82.0, ph: 6.5, rainfall: 202.9 },
  coffee: { N: 91, P: 21, K: 26, temperature: 26.3, humidity: 57.4, ph: 7.3, rainfall: 191.7 },
  cotton: { N: 133, P: 47, K: 24, temperature: 24.4, humidity: 79.2, ph: 7.2, rainfall: 90.8 },
};

const form = document.getElementById("crop-form");
const submitBtn = document.getElementById("submit-btn");
const loading = document.getElementById("loading");
const errorMsg = document.getElementById("error-msg");
const resultArea = document.getElementById("result-area");

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

  const fields = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall"];
  const payload = {};
  for (const f of fields) {
    const input = form.elements[f];
    input.classList.add("touched");
    if (input.value === "") {
      showError("Please fill in every field before submitting.");
      return;
    }
    payload[f] = input.value;
  }

  setLoading(true);
  try {
    const data = await apiPost("/api/predict/crop", payload);
    renderResult(data);
    saveToHistory({ type: "crop", label: data.recommended_crop, confidence: data.confidence });
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
  document.getElementById("result-icon").textContent = data.info.icon || "🌾";
  document.getElementById("result-crop").textContent = data.recommended_crop;
  document.getElementById("result-confidence").textContent =
    `${data.confidence}% confidence`;
  document.getElementById("result-note").textContent = data.info.note || "";
  document.getElementById("result-season").textContent = data.info.season || "—";
  document.getElementById("result-water").textContent = data.info.water || "—";

  const tbody = document.getElementById("matches-body");
  tbody.innerHTML = "";
  data.top_matches.forEach((m) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${m.icon || ""} ${m.crop}</td>
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
  const items = getHistory().filter((h) => h.type === "crop");
  if (items.length === 0) {
    list.innerHTML = '<li class="history-empty">No lookups yet this session.</li>';
    return;
  }
  list.innerHTML = items
    .map((h) => `<li><span style="text-transform:capitalize;">${h.label}</span><span>${h.confidence}% · ${formatWhen(h.when)}</span></li>`)
    .join("");
}

renderHistory();
