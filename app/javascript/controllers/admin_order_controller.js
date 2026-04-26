import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "lineItems", "lineItemRow", "lineItemsContainer", "emptyState",
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
    this.shippingCost = this.hasShippingAmountTarget ? (parseFloat(this.shippingAmountTarget.value) || 85) : 85

    // Restore products submitted before a validation failure
    const submittedEl = document.getElementById("submitted-items-data")
    if (submittedEl) {
      const items = JSON.parse(submittedEl.textContent)
      if (items && items.length > 0) {
        items.forEach(item => {
          if (item.product_id) this._addRow(item.product_id, item.quantity || 1)
        })
      }
    }

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

  addCustomRow() {
    const template = document.getElementById("custom-item-template")
    if (!template) return

    const clone = template.content.cloneNode(true)
    const idx = this.rowIndex++

    clone.querySelectorAll("[data-idx]").forEach(el => {
      const field = el.dataset.idx
      el.name = `order[line_items][${idx}][${field}]`
      el.id   = `line_item_${idx}_${field}`
    })

    this.lineItemsTarget.appendChild(clone)
    // Focus the name field
    const newRow = this.lineItemsTarget.lastElementChild
    newRow?.querySelector("input[data-idx='custom_name']")?.focus()
    this.updateEmptyState()
    this.recalculate()
  }

  _addRow(productId, qty = 1) {
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
      const select  = newRow?.querySelector("select[data-idx='product_id']")
      const qtyInput = newRow?.querySelector("input[data-idx='quantity']")
      if (select) {
        select.value = productId
        if (qtyInput) qtyInput.value = qty
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
    const imageEl       = row.querySelector("[data-cell='product-image']")

    if (product) {
      if (sellPriceCell) sellPriceCell.textContent = this.formatCurrency(product.selling_price)
      if (stockCell)     stockCell.textContent     = product.stock_quantity + " in stock"
      if (qtyInput)      qtyInput.max = product.stock_quantity
      if (imageEl) {
        if (product.image_url) {
          imageEl.src = product.image_url
          imageEl.alt = product.name
          imageEl.classList.remove("hidden")
        } else {
          imageEl.classList.add("hidden")
        }
      }
    } else {
      if (sellPriceCell) sellPriceCell.textContent = "—"
      if (stockCell)     stockCell.textContent     = ""
      if (imageEl)       imageEl.classList.add("hidden")
    }
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  recalculate() {
    let subtotal = 0

    this.lineItemRowTargets.forEach(row => {
      const lineTotalCell = row.querySelector("[data-cell='line-total']")
      const qtyInput = row.querySelector("input[data-idx='quantity']")
      const qty = parseInt(qtyInput?.value) || 0

      if (row.dataset.rowType === "custom") {
        const priceInput = row.querySelector("input[data-custom-price]")
        const price = parseFloat(priceInput?.value) || 0
        if (price > 0 && qty > 0) {
          const lineTotal = price * qty
          subtotal += lineTotal
          if (lineTotalCell) lineTotalCell.textContent = this.formatCurrency(lineTotal)
        } else {
          if (lineTotalCell) lineTotalCell.textContent = "—"
        }
        return
      }

      const select  = row.querySelector("select[data-idx='product_id']")
      if (!select || !qtyInput) return

      const product = this.products[select.value]

      if (product && qty > 0) {
        const lineTotal = product.selling_price * qty
        subtotal += lineTotal
        if (lineTotalCell) lineTotalCell.textContent = this.formatCurrency(lineTotal)
      } else {
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

  // ── Validation ───────────────────────────────────────────────────────────

  validate(event) {
    this._clearValidationErrors()
    let hasErrors = false

    // 1. Customer
    const isGuest = [...this.customerTypeTargets].find(r => r.checked)?.value === "guest"
    if (isGuest) {
      const nameEl  = this.element.querySelector("input[name='guest_name']")
      const emailEl = this.element.querySelector("input[name='guest_email']")

      const phoneEl = this.element.querySelector("input[name='guest_phone']")

      if (!nameEl?.value?.trim()) {
        this._addFieldError(nameEl, "Full name is required")
        hasErrors = true
      }
      if (!emailEl?.value?.trim()) {
        this._addFieldError(emailEl, "Email address is required")
        hasErrors = true
      } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailEl.value.trim())) {
        this._addFieldError(emailEl, "Enter a valid email address")
        hasErrors = true
      }
      if (!phoneEl?.value?.trim()) {
        this._addFieldError(phoneEl, "Phone number is required")
        hasErrors = true
      } else if (!/^[\d\s()\-+.]{7,}$/.test(phoneEl.value.trim())) {
        this._addFieldError(phoneEl, "Enter a valid phone number")
        hasErrors = true
      }
    } else {
      if (!this.userSelectTarget?.value) {
        this._addFieldError(this.userSelectTarget, "Please select a customer")
        hasErrors = true
      }
    }

    // 2. Shipping address
    const addrChecks = [
      [this.addressFullNameTarget, "Recipient name is required"],
      [this.addressStreetTarget,   "Street address is required"],
      [this.addressCityTarget,     "City is required"],
      [this.addressStateTarget,    "State is required"],
    ]
    addrChecks.forEach(([el, msg]) => {
      if (!el?.value?.trim()) {
        this._addFieldError(el, msg)
        hasErrors = true
      }
    })

    const zipEl = this.addressZipTarget
    const zip   = zipEl?.value?.trim()
    if (!zip) {
      this._addFieldError(zipEl, "ZIP code is required")
      hasErrors = true
    } else if (!/^\d{5}(-\d{4})?$/.test(zip)) {
      this._addFieldError(zipEl, "Enter a valid 5-digit ZIP code")
      hasErrors = true
    }

    // 3. At least one valid line item
    const hasValidItem = this.lineItemRowTargets.some(row => {
      if (row.dataset.rowType === "custom") {
        const name  = row.querySelector("input[data-idx='custom_name']")?.value?.trim()
        const price = parseFloat(row.querySelector("input[data-custom-price]")?.value) || 0
        const qty   = parseInt(row.querySelector("input[data-idx='quantity']")?.value)  || 0
        return name && price > 0 && qty >= 1
      } else {
        const pid = row.querySelector("select[data-idx='product_id']")?.value
        const qty = parseInt(row.querySelector("input[data-idx='quantity']")?.value) || 0
        return pid && qty >= 1
      }
    })
    if (!hasValidItem) {
      const heading = this.hasLineItemsContainerTarget
        ? this.lineItemsContainerTarget.querySelector("h2")
        : null
      if (heading) {
        const errEl = document.createElement("p")
        errEl.className = "field-error text-red-600 text-xs mt-1 px-6 pb-2"
        errEl.textContent = "Add at least one product to the order"
        heading.insertAdjacentElement("afterend", errEl)
      }
      hasErrors = true
    }

    if (hasErrors) {
      event.preventDefault()
      const firstError = this.element.querySelector(".field-error")
      firstError?.closest(".bg-white")?.scrollIntoView({ behavior: "smooth", block: "center" })
    }
  }

  _addFieldError(inputEl, message) {
    if (!inputEl) return
    inputEl.classList.add("border-red-400")
    inputEl.classList.remove("border-gray-300")

    const errEl = document.createElement("p")
    errEl.className = "field-error text-red-600 text-xs mt-1"
    errEl.textContent = message
    inputEl.insertAdjacentElement("afterend", errEl)
  }

  _clearValidationErrors() {
    this.element.querySelectorAll(".field-error").forEach(el => el.remove())
    this.element.querySelectorAll(".border-red-400").forEach(el => {
      el.classList.remove("border-red-400")
      el.classList.add("border-gray-300")
    })
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
