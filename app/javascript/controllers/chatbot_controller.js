import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["window", "messages", "input", "button", "badge"]

  connect() {
    this.history = []
    this.open    = false
  }

  toggle() {
    this.open ? this.close() : this.show()
  }

  show() {
    this.open = true
    this.windowTarget.classList.remove("hidden")
    this.windowTarget.classList.add("flex")
    this.badgeTarget.classList.add("hidden")
    this.inputTarget.focus()
    this._scrollToBottom()
  }

  close() {
    this.open = false
    this.windowTarget.classList.add("hidden")
    this.windowTarget.classList.remove("flex")
  }

  async send(event) {
    if (event.type === "keydown" && event.key !== "Enter") return
    if (event.type === "keydown" && event.shiftKey) return

    const text = this.inputTarget.value.trim()
    if (!text) return

    this.inputTarget.value = ""
    this._appendMessage("user", text)
    this.history.push({ role: "user", content: text })

    const thinking = this._appendThinking()
    this.buttonTarget.disabled = true

    try {
      const csrf  = document.querySelector('meta[name="csrf-token"]')?.content
      const res   = await fetch(this.element.dataset.chatUrl, {
        method:  "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf },
        body:    JSON.stringify({ message: text, history: this.history.slice(0, -1) })
      })
      const data = await res.json()

      thinking.remove()

      if (data.reply) {
        this._appendMessage("bot", data.reply)
        this.history.push({ role: "assistant", content: data.reply })
      } else {
        this._appendMessage("bot", data.error || "Sorry, something went wrong.")
      }
    } catch {
      thinking.remove()
      this._appendMessage("bot", "Connection error. Please try again.")
    } finally {
      this.buttonTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  _appendMessage(role, text) {
    const wrap = document.createElement("div")
    wrap.className = role === "user"
      ? "flex justify-end"
      : "flex justify-start"

    const bubble = document.createElement("div")
    bubble.className = role === "user"
      ? "max-w-[80%] bg-amber-800 text-white text-sm px-3 py-2 rounded-2xl rounded-tr-sm leading-relaxed"
      : "max-w-[80%] bg-gray-100 text-gray-800 text-sm px-3 py-2 rounded-2xl rounded-tl-sm leading-relaxed"

    bubble.textContent = text
    wrap.appendChild(bubble)
    this.messagesTarget.appendChild(wrap)
    this._scrollToBottom()
    return wrap
  }

  _appendThinking() {
    const wrap = document.createElement("div")
    wrap.className = "flex justify-start"
    wrap.innerHTML = `
      <div class="bg-gray-100 text-gray-400 text-sm px-3 py-2 rounded-2xl rounded-tl-sm flex gap-1 items-center">
        <span class="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce" style="animation-delay:0ms"></span>
        <span class="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce" style="animation-delay:150ms"></span>
        <span class="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce" style="animation-delay:300ms"></span>
      </div>`
    this.messagesTarget.appendChild(wrap)
    this._scrollToBottom()
    return wrap
  }

  _scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
