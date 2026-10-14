import { useEffect, useState } from "react";
import "./App.css";

import {
  getDashboard,
  runAnalysis,
} from "./api";
function App() {
  const [dashboard, setDashboard] = useState(null);
  const [loading, setLoading] = useState(true);
  const [running, setRunning] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadDashboard();
  }, []);

  async function loadDashboard() {
    try {
      setLoading(true);
      setError(null);

      const data = await getDashboard();

      setDashboard(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleRunAnalysis() {
    console.log("RUN ANALYSIS CLICKED");
    try {
      setRunning(true);
      setError(null);

      await runAnalysis({
        requested_from: "executive-overview",
      });

      await loadDashboard();
    } catch (err) {
      setError(err.message);
    } finally {
      setRunning(false);
    }
  }
  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <div className="brand-mark">IA</div>

          <div>
            <h1>Intelligent Analytics</h1>
            <span>Business Decision Support Platform</span>
          </div>
        </div>

        <div className="system-status">
          <span className="status-dot"></span>
          System Online
        </div>
      </header>

      <div className="layout">
        <aside className="sidebar">
          <div className="section-label">WORKSPACE</div>

          <nav>
            <button className="nav-item active">
              <span>▦</span>
              Overview
            </button>

            <button className="nav-item">
              <span>◈</span>
              Analytics
            </button>

            <button className="nav-item">
              <span>⌁</span>
              Forecasting
            </button>

            <button className="nav-item">
              <span>◉</span>
              Operations
            </button>

            <button className="nav-item">
              <span>✓</span>
              Data Quality
            </button>

            <button className="nav-item">
              <span>⚙</span>
              Automation
            </button>
          </nav>

          <div className="sidebar-footer">
            <span>Platform</span>
            <strong>v1.0</strong>
          </div>
        </aside>

        <main className="main-content">
          <div className="page-header">
            <div>
              <span className="eyebrow">BUSINESS INTELLIGENCE</span>

              <h2>Executive Overview</h2>

              <p>
                Monitor business performance, operational risk,
                and predictive insights from one centralized platform.
              </p>
            </div>

           <button
            className="run-button"
            onClick={handleRunAnalysis}
            disabled={running}
          >
            {running ? "Running..." : "Run Analysis"}
            <span>→</span>
            </button>
          </div>

      <div className="metric-row">
        <div>
          <span>Average Delivery</span>
          <strong>
            {loading
              ? "Loading..."
              : `${dashboard?.business_performance?.average_delivery_days || "0"} days`}
          </strong>
        </div>

        <div>
          <span>Customers</span>
          <strong>
            {loading
              ? "Loading..."
              : Number(
                  dashboard?.business_performance?.total_customers || 0
                ).toLocaleString()}
          </strong>
        </div>

        <div>
          <span>Data Quality</span>
          <strong>
            {loading
              ? "Loading..."
              : dashboard?.automation?.data_quality_status === "PASS"
                ? "100%"
                : "Issues Found"}
          </strong>
        </div>
      </div>

          <section className="content-grid">
            <div className="panel">
              <div className="panel-header">
                <div>
                  <span className="eyebrow">SYSTEM STATUS</span>
                  <h3>Business Health</h3>
                </div>

                <span className="badge warning">
                  {loading
                    ? "Checking..."
                    : dashboard?.automation?.business_status || "Unknown"}
                </span>
              </div>

              <p className="insight">
                Delayed shipments are currently above the configured
                operational threshold and require investigation.
              </p>

              <div className="metric-row">
                <div>
                  <span>Average Delivery</span>
                  <strong>4.10 days</strong>
                </div>

                <div>
                  <span>Customers</span>
                  <strong>22,820</strong>
                </div>

                <div>
                  <span>Data Quality</span>
                  <strong>100%</strong>
                </div>
              </div>
            </div>

            <div className="panel">
              <div className="panel-header">
                <div>
                  <span className="eyebrow">ML FORECAST</span>
                  <h3>Next-Day Revenue</h3>
                </div>
              </div>

              <div className="forecast-value">
                {loading
                  ? "Loading..."
                  : `₹${(
                      Number(dashboard?.forecast?.predicted_revenue || 0) /
                      1000000
                    ).toFixed(2)}M`}
              </div>

              <p className="muted">
                {dashboard?.forecast?.model_name || "Model"}
                {" • "}
                MAPE {dashboard?.forecast?.model_mape || "0"}%
              </p>

              <div className="forecast-date">
                Forecast date:{" "}
                {dashboard?.forecast?.forecast_date
                  ? new Date(dashboard.forecast.forecast_date).toLocaleDateString(
                      "en-GB",
                      {
                        day: "2-digit",
                        month: "short",
                        year: "numeric",
                      }
                    )
                  : "Unavailable"}
              </div>
                          </div>
          </section>

          <section className="activity-panel">
            <div className="panel-header">
              <div>
                <span className="eyebrow">AUTOMATION</span>
                <h3>Latest Analytics Run</h3>
              </div>

              <span className="badge success">
                  {loading
                    ? "CHECKING..."
                    : dashboard?.automation?.execution_status || "UNKNOWN"}
              </span>
            </div>

            <div className="activity-details">
              <div>
                <span>Execution</span>
                <strong>Automated Daily Analytics</strong>
              </div>

              <div>
                <span>Data Quality</span>
                <strong>
                  {loading
                    ? "CHECKING..."
                    : dashboard?.automation?.data_quality_status || "UNKNOWN"}
                </strong>
              </div>

              <div>
                <span>Business Status</span>
                <strong>
                  {loading
                    ? "CHECKING..."
                    : dashboard?.automation?.business_status || "UNKNOWN"}
                </strong>
              </div>

              <div>
                <span>Automation</span>
                <strong>n8n</strong>
              </div>
            </div>
          </section>
        </main>
      </div>
    </div>
  );
}

export default App;