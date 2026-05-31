import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "message", "dontShowToday", "counter", "nav", "prev", "next"]
  static values  = { items: Array }

  connect() {
    const firstIndex = this.itemsValue.findIndex(a => !this._dismissed(a.id))
    if (firstIndex === -1) return
    this.currentIndex = firstIndex
    this._show()
    this.dialogTarget.showModal()
  }

  prev() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this._show()
    }
  }

  next() {
    if (this.currentIndex < this.itemsValue.length - 1) {
      this.currentIndex++
      this._show()
    }
  }

  checkboxChanged() {
    if (!this.dontShowTodayTarget.checked) return
    localStorage.setItem(this._key(this.itemsValue[this.currentIndex].id), new Date().toDateString())
    const nextIndex = this.itemsValue.findIndex((a, i) => i !== this.currentIndex && !this._dismissed(a.id))
    if (nextIndex !== -1) {
      this.currentIndex = nextIndex
      this._show()
    } else {
      this.dialogTarget.close()
    }
  }

  dismiss() {
    this.dialogTarget.close()
  }

  _show() {
    const items = this.itemsValue
    const item  = items[this.currentIndex]

    this.messageTarget.textContent = item.message
    this.dontShowTodayTarget.checked = false

    if (items.length > 1) {
      this.counterTarget.textContent = `${this.currentIndex + 1} of ${items.length}`
      this.navTarget.classList.remove("hidden")
      this.navTarget.classList.add("flex")
      this.prevTarget.disabled = this.currentIndex === 0
      this.nextTarget.disabled = this.currentIndex === items.length - 1
    }
  }

  _key(id)       { return `announcement_dismissed_${id}` }
  _dismissed(id) { return localStorage.getItem(this._key(id)) === new Date().toDateString() }
}
