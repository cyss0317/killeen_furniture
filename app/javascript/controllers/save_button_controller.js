import { Controller } from "@hotwired/stimulus"

// save-button controller
// Gives an inline save button a loading → completed → reset lifecycle.
//
// Usage: attach to the <form> element
//   data-controller="save-button"
//   data-save-button-target="btn"   on the submit button
export default class extends Controller {
  static targets = ["btn"]

  connect() {
    // Listen for Turbo's submit lifecycle on this form
    this.element.addEventListener("turbo:submit-start",  this.onStart.bind(this))
    this.element.addEventListener("turbo:submit-end",    this.onEnd.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start",  this.onStart)
    this.element.removeEventListener("turbo:submit-end",    this.onEnd)
  }

  // Called when user clicks submit (before Turbo sends the request)
  submit(event) {
    this.showLoading()
  }

  onStart() {
    this.showLoading()
  }

  onEnd(event) {
    if (event.detail.success) {
      this.showCompleted()
      setTimeout(() => this.resetBtn(), 1500)
    } else {
      this.resetBtn()
    }
  }

  showLoading() {
    if (!this.hasBtnTarget) return
    const btn = this.btnTarget
    btn.disabled = true
    btn.innerHTML = `
      <svg class="animate-spin h-4 w-4 mx-auto" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
      </svg>`
    btn.classList.add("opacity-75")
  }

  showCompleted() {
    if (!this.hasBtnTarget) return
    const btn = this.btnTarget
    btn.disabled = true
    btn.innerHTML = `
      <span class="flex items-center gap-1">
        <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/>
        </svg>
        Saved
      </span>`
    btn.classList.remove("opacity-75")
    btn.classList.add("bg-green-600")
  }

  resetBtn() {
    if (!this.hasBtnTarget) return
    const btn = this.btnTarget
    btn.disabled = false
    btn.textContent = "Save"
    btn.classList.remove("bg-green-600", "opacity-75")
  }
}
