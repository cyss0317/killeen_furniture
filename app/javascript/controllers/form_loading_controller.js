import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "buttonText", "loadingState"]

  submit(event) {
    // Only proceed if form is valid (handles browser-level validation)
    if (this.element.checkValidity && !this.element.checkValidity()) {
      return
    }

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
    }

    if (this.hasButtonTextTarget) {
      this.buttonTextTarget.classList.add("hidden")
    }

    if (this.hasLoadingStateTarget) {
      this.loadingStateTarget.classList.remove("hidden")
      this.loadingStateTarget.classList.add("flex")
    }
  }
}
