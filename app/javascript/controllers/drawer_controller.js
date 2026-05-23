import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop"]

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    // Reset scroll lock if drawer was open during a Turbo navigation
    document.body.style.overflow = ""
  }

  open() {
    this.panelTarget.classList.remove("translate-x-full")
    this.panelTarget.classList.add("translate-x-0")
    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.add("opacity-100")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.boundHandleKeydown)
    this._trapFocus()
  }

  close() {
    this.panelTarget.classList.remove("translate-x-0")
    this.panelTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
    if (event.key === "Tab") {
      this._handleTabKey(event)
    }
  }

  _trapFocus() {
    const focusable = this.panelTarget.querySelectorAll(
      'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    if (focusable.length > 0) {
      focusable[0].focus()
    }
  }

  _handleTabKey(event) {
    const focusable = Array.from(
      this.panelTarget.querySelectorAll(
        'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])'
      )
    )
    if (focusable.length === 0) return

    const first = focusable[0]
    const last  = focusable[focusable.length - 1]

    if (event.shiftKey) {
      if (document.activeElement === first) {
        event.preventDefault()
        last.focus()
      }
    } else {
      if (document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }
  }

  disconnect() {
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }
}
