import { Controller } from "@hotwired/stimulus"

// Displays a live implied-markup badge next to the selling price input
// in the PO receive form. Mirrors the behaviour on admin/products#show.
//
// Usage (on the <tr>):
//   data-controller="receive-price"
//   data-receive-price-unit-cost-value="49.99"
//
// Targets:
//   price       — the selling-price <input>
//   markup      — <span> that receives the computed markup text
//   markupBadge — wrapper badge element (hidden/shown automatically)
export default class extends Controller {
  static targets = ["price", "markup", "markupBadge"]
  static values  = { unitCost: Number }

  update() {
    const price    = parseFloat(this.priceTarget.value)
    const unitCost = this.unitCostValue

    if (!isFinite(price) || price <= 0 || !isFinite(unitCost) || unitCost <= 0) {
      if (this.hasMarkupBadgeTarget) this.markupBadgeTarget.classList.add("hidden")
      return
    }

    const markup = (((price / unitCost) - 1) * 100).toFixed(1)
    this.markupTarget.textContent = `${markup}%`
    if (this.hasMarkupBadgeTarget) this.markupBadgeTarget.classList.remove("hidden")
  }
}
