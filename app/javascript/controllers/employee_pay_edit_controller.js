import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "employeeName", "form", "amount", "hours", "rate", "description", "paidOn"]

  open(event) {
    const { url, employeeName, amount, hours, rate, description, paidOn } = event.params
    this.formTarget.action = url
    this.employeeNameTarget.textContent = employeeName
    this.amountTarget.value = amount
    this.hoursTarget.value  = hours || ""
    this.rateTarget.value   = rate || ""
    this.descriptionTarget.value = description || ""
    this.paidOnTarget.value = paidOn
    this.dialogTarget.showModal()
  }

  updateTotal() {
    const hours = parseFloat(this.hoursTarget.value) || 0
    const rate  = parseFloat(this.rateTarget.value)  || 0
    if (hours > 0 && rate > 0) {
      this.amountTarget.value = (hours * rate).toFixed(2)
    }
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }
}
