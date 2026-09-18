const health = document.querySelector("#health");
const results = document.querySelector("#results");
let mode = "unknown";

fetch("/api/health").then(r => r.json()).then(data => {
  mode = data.mode;
  health.textContent = JSON.stringify(data, null, 2);
}).catch(error => health.textContent = String(error));

document.querySelector("#search").addEventListener("submit", async event => {
  event.preventDefault();
  const q = new FormData(event.target).get("q");
  const response = await fetch(`/api/products?q=${encodeURIComponent(q)}`);
  const text = JSON.stringify(await response.json(), null, 2);
  // Intentional local teaching branch: TP05 contrasts DOM sinks with textContent.
  if (mode === "vulnerable") results.innerHTML = text;
  else results.textContent = text;
});
