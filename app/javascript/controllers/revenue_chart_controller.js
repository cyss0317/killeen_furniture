import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js"

const usd = (val) => new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(val)

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
    const ctx     = this.element.getContext("2d")
    const revenue = this.revenueValue
    const cost    = this.costValue
    const profit  = revenue.map((r, i) => parseFloat((r - (cost[i] || 0)).toFixed(2)))

    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            label: "Revenue",
            data: revenue,
            borderColor: "#b45309",
            backgroundColor: "rgba(180, 83, 9, 0.07)",
            borderWidth: 2,
            tension: 0.3,
            fill: true,
            pointBackgroundColor: "#b45309",
            pointRadius: 3,
            pointHoverRadius: 5
          },
          {
            label: "Cost",
            data: cost,
            borderColor: "#9ca3af",
            backgroundColor: "rgba(107, 114, 128, 0.05)",
            borderWidth: 2,
            tension: 0.3,
            fill: true,
            pointBackgroundColor: "#9ca3af",
            pointRadius: 3,
            pointHoverRadius: 5
          },
          {
            label: "Profit",
            data: profit,
            borderColor: "#15803d",
            backgroundColor: "rgba(21, 128, 61, 0.10)",
            borderWidth: 2,
            tension: 0.3,
            fill: true,
            pointBackgroundColor: "#15803d",
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
              label: (ctx) => ` ${ctx.dataset.label}: ${usd(ctx.parsed.y)}`
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
