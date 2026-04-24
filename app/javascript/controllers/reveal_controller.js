import { Controller } from "@hotwired/stimulus"

// Fades elements in each time they scroll into view from below.
// Elements stay visible once revealed; re-animates if user scrolls back up
// far enough that the element leaves the bottom of the viewport.
// Usage: data-controller="reveal"
// Optional delay (ms): data-reveal-delay="150"
export default class extends Controller {
  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    if (document.documentElement.hasAttribute("data-turbo-preview")) return

    this.delay = parseInt(this.element.dataset.revealDelay || "0")

    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(22px)"
    this.element.style.transition = `opacity 0.55s ease ${this.delay}ms, transform 0.55s ease ${this.delay}ms`

    this.observer = new IntersectionObserver(
      this._onIntersect.bind(this),
      { threshold: 0.08, rootMargin: "0px 0px -24px 0px" }
    )
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  _onIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // Element scrolled into view — animate in
        this.element.style.transition = `opacity 0.55s ease ${this.delay}ms, transform 0.55s ease ${this.delay}ms`
        this.element.style.opacity = "1"
        this.element.style.transform = "translateY(0)"
      } else if (entry.boundingClientRect.top > 0) {
        // Element exited from the BOTTOM of viewport (user scrolled back up
        // so the element is now below the screen) — reset instantly so it
        // re-animates next time the user scrolls down to it
        this.element.style.transition = "none"
        this.element.style.opacity = "0"
        this.element.style.transform = "translateY(22px)"
      }
      // Element exited from TOP (user scrolled past it downward) — stay visible
    })
  }
}
