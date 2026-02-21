import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lineItems", "row", "productSelect", "skuLabel", "qty", "unitCost", "lineTotal", "grandTotal"]

  connect() {
    const el = document.getElementById("products-data")
    this.products = el ? JSON.parse(el.textContent) : {}
  }

  addProduct() {
    const template = document.getElementById("purchase-order-row-template")
    const clone = template.content.cloneNode(true)

    // Give each cloned row a unique index so name attributes stay unique
    const idx = Date.now()
    clone.querySelectorAll("[name]").forEach(el => {
      el.name = el.name.replace("[][]", `[${idx}][]`)
    })

    this.lineItemsTarget.appendChild(clone)
    this.recalculate()
  }

  removeItem(event) {
    event.currentTarget.closest("tr").remove()
    this.recalculate()
  }

  productChanged(event) {
    const select  = event.currentTarget
    const row     = select.closest("tr")
    const product = this.products[select.value]

    const skuLabel = row.querySelector("[data-purchase-order-target='skuLabel']")
    const costInput = row.querySelector("[data-purchase-order-target='unitCost']")

    if (product) {
      if (skuLabel)  skuLabel.textContent = `SKU: ${product.sku}`
      if (costInput) costInput.value = product.base_cost.toFixed(2)
    } else {
      if (skuLabel)  skuLabel.textContent = ""
      if (costInput) costInput.value = "0.00"
    }

    this.recalculate()
  }

  recalculate() {
    let grandTotal = 0

    this.lineItemsTarget.querySelectorAll("tr").forEach(row => {
      const qty      = parseFloat(row.querySelector("[data-purchase-order-target='qty']")?.value) || 0
      const cost     = parseFloat(row.querySelector("[data-purchase-order-target='unitCost']")?.value) || 0
      const lineTotal = qty * cost

      const lineTotalEl = row.querySelector("[data-purchase-order-target='lineTotal']")
      if (lineTotalEl) lineTotalEl.textContent = this.#formatCurrency(lineTotal)

      grandTotal += lineTotal
    })

    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = this.#formatCurrency(grandTotal)
    }
  }

  #formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(amount)
  }
}
