const API_BASE_URL = "http://127.0.0.1:5000/api";

async function request(endpoint, options = {}) {
  const response = await fetch(
    `${API_BASE_URL}${endpoint}`,
    {
      headers: {
        "Content-Type": "application/json",
        ...options.headers,
      },
      ...options,
    }
  );

  let data;

  try {
    data = await response.json();
  } catch {
    throw new Error(
      `API returned an invalid response (${response.status}).`
    );
  }

  if (!response.ok) {
    throw new Error(
      data.message || "API request failed."
    );
  }

  return data;
}

export async function getHealth() {
  return request("/health");
}

export async function getDashboard() {
  return request("/dashboard");
}

export async function getKPIs() {
  return request("/kpis");
}

export async function getOperations() {
  return request("/operations");
}

export async function getForecast() {
  return request("/forecast");
}

export async function getDataQuality() {
  return request("/data-quality");
}

export async function getAutomationStatus() {
  return request("/automation/status");
}

export async function getAnalyticsHistory(limit = 10) {
  return request(
    `/analytics/history?limit=${limit}`
  );
}

export async function getInsights() {
  return request("/insights");
}

export async function runAnalysis(payload = {}) {
  return request("/automation/run", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}