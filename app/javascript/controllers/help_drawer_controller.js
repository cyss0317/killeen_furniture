import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop"]

  open() {
    this.panelTarget.classList.remove("translate-x-full")
    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.panelTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    document.body.classList.remove("overflow-hidden")
  }
}
