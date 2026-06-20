import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "name", "form"]

  open(event) {
    const { name, url } = event.params
    this.nameTarget.textContent = name
    this.formTarget.action = url
    this.dialogTarget.showModal()
  }

  cancel() {
    this.dialogTarget.close()
  }

  // Close on backdrop click
  backdropClick(event) {
    if (event.target === this.dialogTarget) {
      this.dialogTarget.close()
    }
  }
}
