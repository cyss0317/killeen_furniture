import { Controller } from "@hotwired/stimulus"

// Hides sensitive values behind an eye-icon button.
// Usage:
//   <span data-controller="peekable">
//     <button data-action="click->peekable#toggle" data-peekable-target="btn" ...>eye svg</button>
//     <span data-peekable-target="value" class="hidden">$123.45</span>
//   </span>
export default class extends Controller {
  static targets = ["value", "btn", "eyeOpen", "eyeOff"]

  connect() {
    this._hidden = true
  }

  toggle(e) {
    e.preventDefault()
    this._hidden = !this._hidden
    this.valueTargets.forEach(el => el.classList.toggle("hidden", this._hidden))
    this.eyeOpenTargets.forEach(el => el.classList.toggle("hidden", !this._hidden))
    this.eyeOffTargets.forEach(el => el.classList.toggle("hidden", this._hidden))
  }
}
