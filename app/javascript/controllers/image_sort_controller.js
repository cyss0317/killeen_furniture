import { Controller } from "@hotwired/stimulus"

// Drag-to-reorder vendor image grid.
// Each item has a hidden input carrying the URL; reordering the DOM reorders the submitted array.
export default class extends Controller {
  static targets = ["item", "inputs"]

  connect() {
    this.dragSrc = null
    this.element.querySelectorAll("[data-image-sort-target='item']").forEach(el => {
      this.#attach(el)
    })
  }

  // ── public action ──────────────────────────────────────────────────────────

  toggle(event) {
    // Checkbox toggle — disable hidden input so URL is excluded from submission,
    // and dim the tile visually.
    const item    = event.target.closest("[data-image-sort-target='item']")
    const input   = item.querySelector("input[type='hidden']")
    const checked = event.target.checked

    input.disabled = !checked
    item.classList.toggle("opacity-40",     !checked)
    item.classList.toggle("ring-amber-500",  checked)
    item.classList.toggle("ring-gray-300",  !checked)
    // Prevent dragging removed items
    item.draggable = checked
  }

  // ── drag handlers ──────────────────────────────────────────────────────────

  #attach(el) {
    el.addEventListener("dragstart",  e => this.#onDragStart(e))
    el.addEventListener("dragover",   e => this.#onDragOver(e))
    el.addEventListener("dragenter",  e => this.#onDragEnter(e))
    el.addEventListener("dragleave",  e => this.#onDragLeave(e))
    el.addEventListener("drop",       e => this.#onDrop(e))
    el.addEventListener("dragend",    e => this.#onDragEnd(e))
  }

  #onDragStart(e) {
    this.dragSrc = e.currentTarget
    e.dataTransfer.effectAllowed = "move"
    e.dataTransfer.setData("text/plain", "")          // required for Firefox
    requestAnimationFrame(() => this.dragSrc.classList.add("opacity-30", "scale-95"))
  }

  #onDragOver(e) {
    e.preventDefault()
    e.dataTransfer.dropEffect = "move"
  }

  #onDragEnter(e) {
    const target = e.currentTarget
    if (target !== this.dragSrc) target.classList.add("ring-2", "ring-amber-400")
  }

  #onDragLeave(e) {
    e.currentTarget.classList.remove("ring-2", "ring-amber-400")
  }

  #onDrop(e) {
    e.preventDefault()
    const target = e.currentTarget
    target.classList.remove("ring-2", "ring-amber-400")
    if (!this.dragSrc || target === this.dragSrc) return

    const grid = this.element.querySelector("[data-image-sort-grid]")
    const items = [...grid.children]
    const srcIdx = items.indexOf(this.dragSrc)
    const dstIdx = items.indexOf(target)

    if (srcIdx < dstIdx) {
      grid.insertBefore(this.dragSrc, target.nextSibling)
    } else {
      grid.insertBefore(this.dragSrc, target)
    }

    // Update "Primary" badge — first item is always primary
    this.#refreshBadges()
  }

  #onDragEnd(e) {
    if (this.dragSrc) this.dragSrc.classList.remove("opacity-30", "scale-95")
    this.dragSrc = null
  }

  #refreshBadges() {
    const grid  = this.element.querySelector("[data-image-sort-grid]")
    grid.querySelectorAll("[data-primary-badge]").forEach((badge, i) => {
      badge.classList.toggle("hidden", i !== 0)
    })
  }
}
