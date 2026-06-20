import { Controller } from "@hotwired/stimulus"

// employee-pay controller
// Wires the employee dropdown to show the correct pay-entry fields.
//
// Data expected on the controller element:
//   data-employee-pay-employees-value  — JSON: { "id": { pay_type, pay_rate, name } }
//
// Targets:
//   employeeSelect  — the <select> for employee
//   salarySection   — amount-only section (monthly/salary)
//   hourlySection   — hours + rate section (hourly)
//   hoursInput      — the "hours worked" input
//   rateInput       — the rate-per-hour input
//   amountOutput    — hidden input that carries the final $ amount for both paths
//   amountInput     — visible amount input for salary path
//   amountPreview   — span that shows the computed dollar total for hourly path
export default class extends Controller {
  static targets = [
    "employeeSelect",
    "salarySection",
    "hourlySection",
    "hoursInput",
    "rateInput",
    "amountOutput",
    "amountInput",
    "amountPreview",
    "rateHint",
  ]
  static values = { employees: Object }

  connect() {
    this.refresh()
  }

  refresh() {
    const id = this.employeeSelectTarget.value
    if (!id) {
      this.hideAll()
      return
    }

    const emp = this.employeesValue[id]
    if (!emp) {
      this.hideAll()
      return
    }

    if (emp.pay_type === "hourly") {
      this.salarySectionTarget.classList.add("hidden")
      this.hourlySectionTarget.classList.remove("hidden")
      if (this.hasRateInputTarget && emp.pay_rate) {
        this.rateInputTarget.value = this.rateInputTarget.value || emp.pay_rate
      }
      if (this.hasRateHintTarget && emp.pay_rate) {
        this.rateHintTarget.textContent = `Configured rate: $${emp.pay_rate.toFixed(2)}/hr`
        this.rateHintTarget.classList.remove("hidden")
      }
      this.calculateHourly()
    } else {
      this.hourlySectionTarget.classList.add("hidden")
      this.salarySectionTarget.classList.remove("hidden")
      if (this.hasRateHintTarget) this.rateHintTarget.classList.add("hidden")
    }
  }

  hideAll() {
    this.salarySectionTarget.classList.add("hidden")
    this.hourlySectionTarget.classList.add("hidden")
    if (this.hasRateHintTarget) this.rateHintTarget.classList.add("hidden")
  }

  calculateHourly() {
    const hours = parseFloat(this.hoursInputTarget.value) || 0
    const rate  = parseFloat(this.rateInputTarget.value)  || 0
    const total = (hours * rate).toFixed(2)

    if (this.hasAmountPreviewTarget) {
      this.amountPreviewTarget.textContent = `$${total}`
    }
    if (this.hasAmountOutputTarget) {
      this.amountOutputTarget.value = total
    }
  }
}
