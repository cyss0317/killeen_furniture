import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "employeeSelect",
    "rateInput",
    "hoursInput",
    "amountInput",
    "rateHint",
    "periodPreview",
    "payFields",
  ]
  static values = { employees: Object, periodTotal: Number }

  connect() {
    this.refresh()
  }

  refresh() {
    const id  = this.employeeSelectTarget.value
    const emp = id ? this.employeesValue[id] : null

    if (this.hasPayFieldsTarget) {
      this.payFieldsTarget.classList.toggle("hidden", !emp)
    }

    if (!emp) {
      if (this.hasRateHintTarget) this.rateHintTarget.classList.add("hidden")
      return
    }

    const rate = emp.pay_rate ?? 0
    if (this.hasRateInputTarget) this.rateInputTarget.value = rate

    if (this.hasRateHintTarget) {
      this.rateHintTarget.textContent = rate > 0
        ? `Configured rate: $${Number(rate).toFixed(2)}/hr`
        : "No rate configured"
      this.rateHintTarget.classList.remove("hidden")
    }

    this.calculateAmount()
  }

  calculateAmount() {
    const rate  = parseFloat(this.rateInputTarget.value)  || 0
    const hours = parseFloat(this.hoursInputTarget.value) || 0

    if (rate > 0 && hours > 0) {
      const amount = (rate * hours).toFixed(2)
      if (this.hasAmountInputTarget) this.amountInputTarget.value = amount
      this.setPeriodPreview(amount)
    } else {
      this.setPeriodPreview(this.hasAmountInputTarget ? (parseFloat(this.amountInputTarget.value) || 0) : 0)
    }
  }

  amountChanged() {
    const rate  = parseFloat(this.rateInputTarget.value)  || 0
    const hours = parseFloat(this.hoursInputTarget.value) || 0
    if (rate > 0 && hours > 0) return  // rate×hours takes priority; don't let manual edits override
    this.setPeriodPreview(parseFloat(this.amountInputTarget.value) || 0)
  }

  setPeriodPreview(entryAmount) {
    if (!this.hasPeriodPreviewTarget) return
    const total = this.periodTotalValue + parseFloat(entryAmount || 0)
    this.periodPreviewTarget.textContent = new Intl.NumberFormat("en-US", {
      style: "currency", currency: "USD"
    }).format(total)
  }
}
