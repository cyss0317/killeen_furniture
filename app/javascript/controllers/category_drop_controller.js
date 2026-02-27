import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dragStart(event) {
    const pill = event.currentTarget
    event.dataTransfer.setData("application/x-product-id", pill.dataset.productId)
    event.dataTransfer.setData("application/x-category-id", pill.dataset.categoryId)
    event.dataTransfer.effectAllowed = "move"
    this._dragging = pill
    // Defer so the drag ghost captures the normal appearance first
    requestAnimationFrame(() => pill.classList.add("opacity-40"))
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-40")
    this._dragging = null
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    this._highlight(event.currentTarget, true)
  }

  dragLeave(event) {
    if (event.relatedTarget && event.currentTarget.contains(event.relatedTarget)) return
    this._highlight(event.currentTarget, false)
  }

  async drop(event) {
    event.preventDefault()
    const zone = event.currentTarget
    this._highlight(zone, false)

    const productId      = event.dataTransfer.getData("application/x-product-id")
    const fromCategoryId = event.dataTransfer.getData("application/x-category-id")
    const toCategoryId   = zone.dataset.categoryId

    if (!productId || toCategoryId === fromCategoryId) return

    const pill       = this._dragging
    const csrfToken  = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const res  = await fetch(`/admin/products/${productId}/move`, {
        method:  "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body:    JSON.stringify({ category_id: toCategoryId })
      })
      const json = await res.json()
      if (!res.ok) { alert(json.error || "Failed to move product"); return }

      if (pill) {
        pill.dataset.categoryId = toCategoryId
        const toContainer = zone.querySelector("[data-pills-container]")
        if (toContainer) toContainer.appendChild(pill)
      }

      this._adjustCount(fromCategoryId, -1)
      this._adjustCount(toCategoryId,   +1)
    } catch (e) {
      alert("Failed to move product: " + e.message)
    }
  }

  _highlight(zone, on) {
    zone.classList.toggle("ring-2",         on)
    zone.classList.toggle("ring-inset",     on)
    zone.classList.toggle("ring-amber-400", on)
    zone.classList.toggle("bg-amber-50",    on)
  }

  _adjustCount(categoryId, delta) {
    const el = this.element.querySelector(`[data-count-for="${categoryId}"]`)
    if (el) el.textContent = Math.max(0, parseInt(el.textContent, 10) + delta)
  }
}
