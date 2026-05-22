import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["kindRow"]

  connect() {
    this.toggle()
  }

  toggle(event) {
    const select = event ? event.target : this.element.querySelector("select[name*='role']")
    const isAdmin = select && select.value !== "customer"
    this.kindRowTargets.forEach(el => el.classList.toggle("hidden", !isAdmin))
  }
}
