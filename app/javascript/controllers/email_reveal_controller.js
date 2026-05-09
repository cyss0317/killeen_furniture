import { Controller } from "@hotwired/stimulus"

// Decodes a ROT13-encoded email stored in a data attribute and opens mailto.
// The real email address never appears in the HTML source, only a ROT13 version.
export default class extends Controller {
  open(event) {
    event.preventDefault()
    const encoded = this.element.dataset.r
    if (!encoded) return
    const email = encoded.replace(/[A-Za-z]/g, c => {
      const base = c <= "Z" ? 65 : 97
      return String.fromCharCode(((c.charCodeAt(0) - base + 13) % 26) + base)
    })
    window.location.href = `mailto:${email}`
  }
}
