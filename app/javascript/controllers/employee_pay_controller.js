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
      // Pre-fill rate from the employee's stored pay_rate
      if (this.hasRateInputTarget && emp.pay_rate) {
        this.rateInputTarget.value = this.rateInputTarget.value || emp.pay_rate
      }
      this.calculateHourly()
    } else {
      // monthly / salary
      this.hourlySectionTarget.classList.add("hidden")
      this.salarySectionTarget.classList.remove("hidden")
    }
  }

  hideAll() {
    this.salarySectionTarget.classList.add("hidden")
    this.hourlySectionTarget.classList.add("hidden")
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
