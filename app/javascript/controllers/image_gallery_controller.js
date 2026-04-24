import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["main", "thumb", "prev", "next"]

  connect() {
    this.index = 0
    this._update()
  }

  prev() {
    this.index = (this.index - 1 + this.thumbTargets.length) % this.thumbTargets.length
    this._update()
  }

  next() {
    this.index = (this.index + 1) % this.thumbTargets.length
    this._update()
  }

  select(event) {
    this.index = parseInt(event.currentTarget.dataset.galleryIndex)
    this._update()
  }

  _update() {
    const thumbs = this.thumbTargets
    if (!thumbs.length) return

    this.mainTarget.src = thumbs[this.index].dataset.gallerySrc

    thumbs.forEach((t, i) => {
      t.classList.toggle("border-warm-600", i === this.index)
      t.classList.toggle("border-transparent", i !== this.index)
    })

    // Hide arrows when only one image
    const single = thumbs.length <= 1
    if (this.hasPrevTarget) this.prevTarget.classList.toggle("hidden", single)
    if (this.hasNextTarget) this.nextTarget.classList.toggle("hidden", single)
  }
}
