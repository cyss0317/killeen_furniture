import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js"

export default class extends Controller {
  static values = {
    labels:  Array,
    revenue: Array,
    cost:    Array
  }

  connect() {
    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  renderChart() {
    const ctx = this.element.getContext("2d")

    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            label: "Revenue",
            data: this.revenueValue,
            borderColor: "#b45309",
            backgroundColor: "rgba(180, 83, 9, 0.08)",
            borderWidth: 2,
            tension: 0.3,
            fill: true,
            pointBackgroundColor: "#b45309",
            pointRadius: 3,
            pointHoverRadius: 5
          },
          {
            label: "Cost",
            data: this.costValue,
            borderColor: "#6b7280",
            backgroundColor: "rgba(107, 114, 128, 0.06)",
            borderWidth: 2,
            tension: 0.3,
            fill: true,
            pointBackgroundColor: "#6b7280",
            pointRadius: 3,
            pointHoverRadius: 5
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: {
            position: "top",
            labels: { font: { family: "Inter", size: 12 }, color: "#374151" }
          },
          tooltip: {
            callbacks: {
              label: (ctx) => {
                const val = ctx.parsed.y
                return ` ${ctx.dataset.label}: ${new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(val)}`
              }
            }
          }
        },
        scales: {
          x: {
            grid: { color: "rgba(0,0,0,0.04)" },
            ticks: { font: { family: "Inter", size: 11 }, color: "#6b7280" }
          },
          y: {
            grid: { color: "rgba(0,0,0,0.04)" },
            ticks: {
              font: { family: "Inter", size: 11 },
              color: "#6b7280",
              callback: (val) => "$" + val.toLocaleString()
            }
          }
        }
      }
    })
  }
}
