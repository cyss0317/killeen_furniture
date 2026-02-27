import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "liveMarkup", "liveMarkupContainer"]
  static values = { baseCost: Number }

  connect() {
    this.calculateMarkup()
  }

  toggle(event) {
    if (event) event.preventDefault()
    this.displayTarget.classList.toggle("hidden")
    this.formTarget.classList.toggle("hidden")
  }

  showForm() {
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    this.calculateMarkup()
  }

  hideForm() {
    this.displayTarget.classList.remove("hidden")
    this.formTarget.classList.add("hidden")
  }

  calculateMarkup() {
    const input = this.formTarget.querySelector('input[name="selling_price"]')
    if (!input) return

    const newPrice = parseFloat(input.value)
    const baseCost = this.baseCostValue

    if (isNaN(newPrice) || newPrice <= 0 || isNaN(baseCost) || baseCost <= 0) {
      if (this.hasLiveMarkupContainerTarget) this.liveMarkupContainerTarget.classList.add("hidden")
      this.liveMarkupTarget.textContent = ""
      return
    }

    const markup = (((newPrice / baseCost) - 1) * 100).toFixed(2)
    this.liveMarkupTarget.textContent = `${markup}%`
    if (this.hasLiveMarkupContainerTarget) this.liveMarkupContainerTarget.classList.remove("hidden")
  }
}
