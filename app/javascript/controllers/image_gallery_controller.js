import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["main", "videoFrame", "thumb", "prev", "next"]

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

    const current = thumbs[this.index]
    const isVideo = current.dataset.galleryType === "video"

    if (isVideo) {
      // Show iframe, hide image
      const videoId = current.dataset.galleryVideoId
      if (this.hasVideoFrameTarget) {
        this.videoFrameTarget.src = `https://www.youtube.com/embed/${videoId}?autoplay=1`
        this.videoFrameTarget.classList.remove("hidden")
      }
      this.mainTarget.classList.add("hidden")
    } else {
      // Show image, stop and hide iframe
      this.mainTarget.src = current.dataset.gallerySrc
      this.mainTarget.classList.remove("hidden")
      if (this.hasVideoFrameTarget) {
        this.videoFrameTarget.src = ""
        this.videoFrameTarget.classList.add("hidden")
      }
    }

    thumbs.forEach((t, i) => {
      t.classList.toggle("border-warm-600", i === this.index)
      t.classList.toggle("border-transparent", i !== this.index)
    })

    const single = thumbs.length <= 1
    if (this.hasPrevTarget) this.prevTarget.classList.toggle("hidden", single)
    if (this.hasNextTarget) this.nextTarget.classList.toggle("hidden", single)
  }
}
