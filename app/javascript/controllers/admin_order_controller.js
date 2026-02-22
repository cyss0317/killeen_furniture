import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "lineItems", "lineItemRow", "emptyState",
    "subtotal", "shipping", "tax", "grandTotal",
    "customerType", "userSection", "guestSection",
    "userSelect", "shippingZone",
    "addressFullName", "addressStreet", "addressCity", "addressState", "addressZip",
    "calculateShippingBtn", "shippingError", "shippingAmount", "deliveryZoneId",
    "browserPanel", "browserToggle", "browserSearch", "browserCategory",
    "browserColor", "browserInStock", "browserRow", "browserEmpty"
  ]

  connect() {
    // Parse product catalog from embedded JSON
    const dataEl = document.getElementById("products-data")
    this.products = dataEl ? JSON.parse(dataEl.textContent) : {}

    // Parse tax rate
    const taxEl = document.getElementById("tax-rate-data")
    this.taxRate = taxEl ? parseFloat(taxEl.textContent) : 0

    this.rowIndex = this.lineItemRowTargets.length
    this.shippingCost = 0
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

    // Update category dropdown: show only categories that have products matching current color+search+stock
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

    // Update color dropdown: show only colors that have products matching current category+search+stock
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

    // Apply all filters to rows
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

    // If the product is already in the order, increment its quantity instead
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

    // Pre-select the product and populate pricing cells
    if (productId) {
      const newRow = this.lineItemRowTargets[this.lineItemRowTargets.length - 1]
      const select = newRow.querySelector("select[data-idx='product_id']")
      if (select) {
        select.value = productId
        select.dispatchEvent(new Event("change"))
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
    const row     = event.currentTarget.closest("tr")
    const product = this.products[event.currentTarget.value]

    if (product) {
      row.querySelector("[data-cell='base-cost']").textContent   = this.formatCurrency(product.base_cost)
      row.querySelector("[data-cell='markup']").textContent      = product.markup_percentage + "%"
      row.querySelector("[data-cell='sell-price']").textContent  = this.formatCurrency(product.selling_price)
      row.querySelector("[data-cell='stock']").textContent       = product.stock_quantity + " in stock"
      const qtyInput = row.querySelector("[data-qty]")
      if (qtyInput) qtyInput.max = product.stock_quantity
    } else {
      row.querySelector("[data-cell='base-cost']").textContent   = "—"
      row.querySelector("[data-cell='markup']").textContent      = "—"
      row.querySelector("[data-cell='sell-price']").textContent  = "—"
      row.querySelector("[data-cell='stock']").textContent       = ""
    }

    this.recalculate()
  }

  quantityChanged() {
    this.recalculate()
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

    const tax = subtotal * (this.taxRate / 100)
    const grandTotal = subtotal + this.shippingCost + tax

    if (this.hasSubtotalTarget)   this.subtotalTarget.textContent   = this.formatCurrency(subtotal)
    if (this.hasTaxTarget)        this.taxTarget.textContent        = this.formatCurrency(tax)
    if (this.hasGrandTotalTarget) this.grandTotalTarget.textContent = this.formatCurrency(grandTotal)
  }

  // ── Shipping ──────────────────────────────────────────────────────────────

  async calculateShipping() {
    const zip = this.addressZipTarget?.value?.trim()
    if (!zip) {
      if (this.hasShippingErrorTarget) this.shippingErrorTarget.textContent = "Please enter a ZIP code first."
      return
    }

    const items = []
    this.lineItemRowTargets.forEach(row => {
      const select   = row.querySelector("select[data-idx='product_id']")
      const qtyInput = row.querySelector("input[data-idx='quantity']")
      if (select?.value && parseInt(qtyInput?.value) > 0) {
        items.push({ product_id: select.value, quantity: qtyInput.value })
      }
    })

    this.calculateShippingBtnTarget.disabled = true
    this.calculateShippingBtnTarget.textContent = "Calculating..."

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const formData = new FormData()
      formData.append("zip_code", zip)
      items.forEach((item, i) => {
        formData.append(`line_items[${i}][product_id]`, item.product_id)
        formData.append(`line_items[${i}][quantity]`, item.quantity)
      })

      const resp = await fetch(this.element.dataset.calculateShippingUrl, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken },
        body: formData
      })
      const data = await resp.json()

      if (data.error) {
        if (this.hasShippingErrorTarget) this.shippingErrorTarget.textContent = data.error
        if (this.hasShippingTarget)      this.shippingTarget.textContent      = "—"
        this.shippingCost = 0
        if (this.hasShippingAmountTarget) this.shippingAmountTarget.value = 0
      } else {
        if (this.hasShippingErrorTarget) this.shippingErrorTarget.textContent = ""
        if (this.hasShippingTarget)      this.shippingTarget.textContent      = this.formatCurrency(data.cost) + (data.zone_name ? ` (${data.zone_name})` : "")
        this.shippingCost = data.cost
        if (this.hasShippingAmountTarget) this.shippingAmountTarget.value = data.cost
      }
      this.recalculate()
    } catch (e) {
      if (this.hasShippingErrorTarget) this.shippingErrorTarget.textContent = "Error calculating shipping."
    } finally {
      this.calculateShippingBtnTarget.disabled = false
      this.calculateShippingBtnTarget.textContent = "Calculate Shipping"
    }
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
