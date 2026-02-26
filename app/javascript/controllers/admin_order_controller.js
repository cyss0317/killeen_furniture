import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "lineItems", "lineItemRow", "emptyState",
    "subtotal", "tax", "grandTotal", "discount", "shippingAmount",
    "customerType", "userSection", "guestSection",
    "userSelect",
    "addressFullName", "addressStreet", "addressCity", "addressState", "addressZip",
    "browserPanel", "browserToggle", "browserSearch", "browserCategory",
    "browserColor", "browserInStock", "browserRow", "browserEmpty"
  ]

  connect() {
    const dataEl = document.getElementById("products-data")
    this.products = dataEl ? JSON.parse(dataEl.textContent) : {}

    const taxEl = document.getElementById("tax-rate-data")
    this.taxRate = taxEl ? parseFloat(taxEl.textContent) : 0

    this.rowIndex = this.lineItemRowTargets.length
    this.shippingCost = this.hasShippingAmountTarget ? (parseFloat(this.shippingAmountTarget.value) || 0) : 0
    this.recalculate()
  }

  // ── Customer ─────────────────────────────────────────────────────────────

  customerTypeChanged(event) {
    const isGuest = event.target.value === "guest"
    this.userSectionTarget.classList.toggle("hidden", isGuest)
    this.guestSectionTarget.classList.toggle("hidden", !isGuest)
    if (!isGuest) this.loadUserAddress()
  }

  userChanged() {
    this.loadUserAddress()
  }

  loadUserAddress() {
    const userId = this.userSelectTarget.value
    if (!userId) return
    const usersEl = document.getElementById("users-data")
    if (!usersEl) return
    const users = JSON.parse(usersEl.textContent)
    const userData = users[userId]
    if (userData && userData.default_address) {
      const addr = userData.default_address
      if (this.hasAddressFullNameTarget) this.addressFullNameTarget.value = addr.full_name || ""
      if (this.hasAddressStreetTarget)   this.addressStreetTarget.value   = addr.street_address || ""
      if (this.hasAddressCityTarget)     this.addressCityTarget.value     = addr.city || ""
      if (this.hasAddressStateTarget)    this.addressStateTarget.value    = addr.state || ""
      if (this.hasAddressZipTarget)      this.addressZipTarget.value      = addr.zip_code || ""
    }
  }

  // ── Product Browser ───────────────────────────────────────────────────────

  toggleBrowser() {
    const isNowHidden = this.browserPanelTarget.classList.toggle("hidden")
    if (this.hasBrowserToggleTarget) {
      this.browserToggleTarget.textContent = isNowHidden ? "Browse Products" : "Hide Browser"
    }
    if (!isNowHidden && this.hasBrowserSearchTarget) {
      this.browserSearchTarget.focus()
    }
  }

  filterBrowser() {
    const search      = this.hasBrowserSearchTarget   ? this.browserSearchTarget.value.toLowerCase().trim() : ""
    const categoryId  = this.hasBrowserCategoryTarget ? this.browserCategoryTarget.value : ""
    const color       = this.hasBrowserColorTarget    ? this.browserColorTarget.value.toLowerCase() : ""
    const inStockOnly = this.hasBrowserInStockTarget  ? this.browserInStockTarget.checked : false

    const rows = this.browserRowTargets

    const baseMatch = row =>
      (!search     || row.dataset.searchText.includes(search)) &&
      (!inStockOnly || row.dataset.inStock === "true")

    if (this.hasBrowserCategoryTarget) {
      const validCatIds = new Set(
        rows.filter(r => baseMatch(r) && (!color || r.dataset.color === color))
            .map(r => r.dataset.categoryId)
      )
      this.browserCategoryTarget.querySelectorAll("option").forEach(opt => {
        if (!opt.value) return
        opt.hidden = !validCatIds.has(opt.value)
      })
    }

    if (this.hasBrowserColorTarget) {
      const validColors = new Set(
        rows.filter(r => baseMatch(r) && (!categoryId || r.dataset.categoryId === categoryId))
            .map(r => r.dataset.color).filter(Boolean)
      )
      this.browserColorTarget.querySelectorAll("option").forEach(opt => {
        if (!opt.value) return
        opt.hidden = !validColors.has(opt.value)
      })
    }

    let visibleCount = 0
    rows.forEach(row => {
      const visible =
        baseMatch(row) &&
        (!categoryId || row.dataset.categoryId === categoryId) &&
        (!color      || row.dataset.color === color)
      row.classList.toggle("hidden", !visible)
      if (visible) visibleCount++
    })

    if (this.hasBrowserEmptyTarget) {
      this.browserEmptyTarget.classList.toggle("hidden", visibleCount > 0)
    }
  }

  addProductFromBrowser(event) {
    const productId = event.currentTarget.dataset.productId

    const existingRow = this.lineItemRowTargets.find(row =>
      row.querySelector("select[data-idx='product_id']")?.value === productId
    )
    if (existingRow) {
      const qtyInput = existingRow.querySelector("input[data-idx='quantity']")
      if (qtyInput) {
        qtyInput.value = parseInt(qtyInput.value) + 1
        this.recalculate()
      }
      return
    }

    this._addRow(productId)
  }

  // ── Line Items ────────────────────────────────────────────────────────────

  addProduct() {
    this._addRow(null)
  }

  _addRow(productId) {
    const template = document.getElementById("line-item-template")
    if (!template) return

    const clone = template.content.cloneNode(true)
    const idx = this.rowIndex++

    clone.querySelectorAll("[data-idx]").forEach(el => {
      const field = el.dataset.idx
      el.name = `order[line_items][${idx}][${field}]`
      el.id   = `line_item_${idx}_${field}`
    })

    this.lineItemsTarget.appendChild(clone)

    if (productId) {
      const newRow = this.lineItemsTarget.lastElementChild
      const select = newRow?.querySelector("select[data-idx='product_id']")
      if (select) {
        select.value = productId
        this._populateRow(newRow, productId)
        this.recalculate()
      }
    }

    this.updateEmptyState()
  }

  removeItem(event) {
    event.currentTarget.closest("tr").remove()
    this.recalculate()
    this.updateEmptyState()
  }

  productChanged(event) {
    const row       = event.currentTarget.closest("tr")
    const productId = event.currentTarget.value
    this._populateRow(row, productId)
    this.recalculate()
  }

  quantityChanged() {
    this.recalculate()
  }

  discountChanged() {
    this.recalculate()
  }

  shippingChanged() {
    this.shippingCost = parseFloat(this.shippingAmountTarget.value) || 0
    this.recalculate()
  }

  // ── Row population ────────────────────────────────────────────────────────

  _populateRow(row, productId) {
    const product       = this.products[productId]
    const sellPriceCell = row.querySelector("[data-cell='sell-price']")
    const stockCell     = row.querySelector("[data-cell='stock']")
    const qtyInput      = row.querySelector("[data-qty]")

    if (product) {
      if (sellPriceCell) sellPriceCell.textContent = this.formatCurrency(product.selling_price)
      if (stockCell)     stockCell.textContent     = product.stock_quantity + " in stock"
      if (qtyInput)      qtyInput.max = product.stock_quantity
    } else {
      if (sellPriceCell) sellPriceCell.textContent = "—"
      if (stockCell)     stockCell.textContent     = ""
    }
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  recalculate() {
    let subtotal = 0

    this.lineItemRowTargets.forEach(row => {
      const select   = row.querySelector("select[data-idx='product_id']")
      const qtyInput = row.querySelector("input[data-idx='quantity']")
      if (!select || !qtyInput) return

      const product = this.products[select.value]
      const qty = parseInt(qtyInput.value) || 0

      if (product && qty > 0) {
        const lineTotal = product.selling_price * qty
        subtotal += lineTotal
        const lineTotalCell = row.querySelector("[data-cell='line-total']")
        if (lineTotalCell) lineTotalCell.textContent = this.formatCurrency(lineTotal)
      } else {
        const lineTotalCell = row.querySelector("[data-cell='line-total']")
        if (lineTotalCell) lineTotalCell.textContent = "—"
      }
    })

    const discount   = this.hasDiscountTarget ? (parseFloat(this.discountTarget.value) || 0) : 0
    const tax        = subtotal * (this.taxRate / 100)
    const grandTotal = Math.max(0, subtotal + this.shippingCost + tax - discount)

    if (this.hasSubtotalTarget)   this.subtotalTarget.textContent   = this.formatCurrency(subtotal)
    if (this.hasTaxTarget)        this.taxTarget.textContent        = this.formatCurrency(tax)
    if (this.hasGrandTotalTarget) this.grandTotalTarget.textContent = this.formatCurrency(grandTotal)
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  updateEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.toggle("hidden", this.lineItemRowTargets.length > 0)
    }
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(amount)
  }
}
