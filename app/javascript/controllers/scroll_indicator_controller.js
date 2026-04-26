import { Controller } from "@hotwired/stimulus"

// Tracks scroll position in the main content area and reflects it as a
// progress bar + percentage label in the admin sidebar.
export default class extends Controller {
  static targets = ["content", "bar", "label"]

  connect() {
    this._update = this.update.bind(this)
    if (this.hasContentTarget) {
      this.contentTarget.addEventListener("scroll", this._update, { passive: true })
      this.update()
    }
  }

  disconnect() {
    if (this.hasContentTarget) {
      this.contentTarget.removeEventListener("scroll", this._update)
    }
  }

  update() {
    const el = this.contentTarget
    const scrollable = el.scrollHeight - el.clientHeight
    const pct = scrollable > 0 ? Math.round((el.scrollTop / scrollable) * 100) : 0
    this.barTarget.style.width = `${pct}%`
    this.barTarget.setAttribute("aria-valuenow", pct)
    if (this.hasLabelTarget) this.labelTarget.textContent = `${pct}%`
  }
}
