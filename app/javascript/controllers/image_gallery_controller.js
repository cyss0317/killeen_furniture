import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["main", "videoFrame", "thumb", "prev", "next", "lightbox", "lightboxImg", "lightboxThumb"]

  connect() {
    this.index = 0
    this._update()
    this._handleKeydown = this._onKeydown.bind(this)
    // Cached direct element refs used after portaling to body
    this._lbEl     = null
    this._lbImgEl  = null
    this._lbThumbs = []
  }

  disconnect() {
    document.removeEventListener("keydown", this._handleKeydown)
    if (this._lbEl) this.element.appendChild(this._lbEl)
  }

  prev(event) {
    event?.stopPropagation()
    this.index = (this.index - 1 + this.thumbTargets.length) % this.thumbTargets.length
    this._update()
    this._syncLightbox()
  }

  next(event) {
    event?.stopPropagation()
    this.index = (this.index + 1) % this.thumbTargets.length
    this._update()
    this._syncLightbox()
  }

  select(event) {
    this.index = parseInt(event.currentTarget.dataset.galleryIndex)
    this._update()
  }

  openLightbox() {
    if (!this.hasLightboxTarget || !this.hasLightboxImgTarget) return
    const current = this.thumbTargets[this.index]
    if (!current || current.dataset.galleryType === "video") return

    // Cache Stimulus targets BEFORE moving — they disconnect once outside the controller element
    this._lbEl     = this.lightboxTarget
    this._lbImgEl  = this.lightboxImgTarget
    this._lbThumbs = [...this.lightboxThumbTargets]

    this._lbImgEl.src = current.dataset.gallerySrc

    // Portal to <body> so fixed positioning is relative to the viewport,
    // not trapped inside any ancestor stacking context.
    document.body.appendChild(this._lbEl)
    this._lbEl.classList.remove("hidden")
    document.addEventListener("keydown", this._handleKeydown)
    this._syncLightbox()
  }

  closeLightbox() {
    if (!this._lbEl) return
    this._lbEl.classList.add("hidden")
    // Return element to controller so targets reconnect for next open
    this.element.appendChild(this._lbEl)
    this._lbEl    = null
    this._lbImgEl = null
    this._lbThumbs = []
    document.removeEventListener("keydown", this._handleKeydown)
  }

  selectLightbox(event) {
    event.stopPropagation()
    this.index = parseInt(event.currentTarget.dataset.lightboxIndex)
    this._update()
    this._syncLightbox()
  }

  _onKeydown(e) {
    if (e.key === "Escape")      this.closeLightbox()
    if (e.key === "ArrowRight")  this.next()
    if (e.key === "ArrowLeft")   this.prev()
  }

  _syncLightbox() {
    if (!this._lbEl || this._lbEl.classList.contains("hidden")) return
    const current = this.thumbTargets[this.index]
    if (current && current.dataset.galleryType !== "video") {
      this._lbImgEl.src = current.dataset.gallerySrc
    }
    this._lbThumbs.forEach((t, i) => {
      t.classList.toggle("ring-2",      i === this.index)
      t.classList.toggle("ring-white",  i === this.index)
      t.classList.toggle("opacity-100", i === this.index)
      t.classList.toggle("opacity-50",  i !== this.index)
    })
  }

  _update() {
    const thumbs = this.thumbTargets
    if (!thumbs.length) return

    const current = thumbs[this.index]
    const isVideo = current.dataset.galleryType === "video"

    if (isVideo) {
      const videoId = current.dataset.galleryVideoId
      if (this.hasVideoFrameTarget) {
        this.videoFrameTarget.src = `https://www.youtube.com/embed/${videoId}?autoplay=1`
        this.videoFrameTarget.classList.remove("hidden")
      }
      this.mainTarget.classList.add("hidden")
    } else {
      this.mainTarget.src = current.dataset.gallerySrc
      this.mainTarget.classList.remove("hidden")
      if (this.hasVideoFrameTarget) {
        this.videoFrameTarget.src = ""
        this.videoFrameTarget.classList.add("hidden")
      }
    }

    thumbs.forEach((t, i) => {
      t.classList.toggle("border-warm-600",   i === this.index)
      t.classList.toggle("border-transparent", i !== this.index)
    })

    const single = thumbs.length <= 1
    if (this.hasPrevTarget) this.prevTarget.classList.toggle("hidden", single)
    if (this.hasNextTarget) this.nextTarget.classList.toggle("hidden", single)
  }
}
