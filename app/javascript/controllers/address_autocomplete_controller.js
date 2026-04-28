import { Controller } from "@hotwired/stimulus"

const STATE_ABBR = {
  "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
  "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
  "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
  "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
  "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
  "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
  "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV",
  "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY",
  "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK",
  "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
  "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
  "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
  "Wisconsin": "WI", "Wyoming": "WY", "District of Columbia": "DC"
}

const MIN_CHARS = 4

export default class extends Controller {
  static targets = ["streetInput", "dropdown", "cityField", "stateField", "zipField"]
  static values  = { url: String }

  connect() {
    this._abort = null
    this._boundClose = this._closeOnOutsideClick.bind(this)
    document.addEventListener("click", this._boundClose)
  }

  disconnect() {
    this._abort?.abort()
    document.removeEventListener("click", this._boundClose)
  }

  search() {
    const query = this.streetInputTarget.value.trim()

    // Cancel any in-flight request immediately when the user types
    this._abort?.abort()

    if (query.length < 1) {
      this._hideDropdown()
      return
    }

    if (query.length < MIN_CHARS) {
      this._showHint(`Keep typing — need ${MIN_CHARS - query.length} more character${MIN_CHARS - query.length === 1 ? "" : "s"}…`)
      return
    }

    // Fetch immediately — no debounce
    this._showLoading()
    this._fetch(query)
  }

  async _fetch(query) {
    this._abort = new AbortController()

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("q", query)

      const res  = await fetch(url, { signal: this._abort.signal })
      const data = await res.json()
      this._renderResults(data)
    } catch (err) {
      if (err.name !== "AbortError") this._hideDropdown()
    }
  }

  _renderResults(results) {
    this.dropdownTarget.innerHTML = ""

    results.forEach(r => {
      const addr     = r.address || {}
      const street   = [addr.house_number, addr.road].filter(Boolean).join(" ") ||
                       addr.pedestrian || addr.path || ""
      const city     = addr.city || addr.town || addr.village || addr.hamlet || addr.county || ""
      const stateRaw = addr.state || ""
      const state    = STATE_ABBR[stateRaw] ||
                       (addr["ISO3166-2-lvl4"] || "").split("-")[1] ||
                       stateRaw
      const zip      = (addr.postcode || "").split("-")[0]

      const label    = street || r.display_name.split(",")[0]
      const sublabel = [city, state, zip].filter(Boolean).join(", ")

      const li = document.createElement("li")
      li.className = "px-4 py-2.5 cursor-pointer hover:bg-amber-50 border-b border-gray-100 last:border-0"
      li.innerHTML = `
        <p class="text-sm font-medium text-gray-800">${this._esc(label)}</p>
        <p class="text-xs text-gray-400">${this._esc(sublabel)}</p>
      `
      li.addEventListener("mousedown", (e) => {
        e.preventDefault()
        this._selectAddress({ street: street || label, city, state, zip })
      })

      this.dropdownTarget.appendChild(li)
    })

    if (this.dropdownTarget.children.length === 0) {
      this._showHint("No addresses found — try a different search.")
    } else {
      this.dropdownTarget.classList.remove("hidden")
    }
  }

  _selectAddress({ street, city, state, zip }) {
    this.streetInputTarget.value = street
    if (this.hasCityFieldTarget)  this.cityFieldTarget.value  = city
    if (this.hasStateFieldTarget) this.stateFieldTarget.value = state
    if (this.hasZipFieldTarget)   this.zipFieldTarget.value   = zip

    this._hideDropdown()
    this.zipFieldTarget?.dispatchEvent(new Event("input", { bubbles: true }))
  }

  _showLoading() {
    this.dropdownTarget.innerHTML = `
      <li class="flex items-center gap-3 px-4 py-3 text-sm text-gray-500">
        <svg class="animate-spin w-4 h-4 text-amber-600 shrink-0" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
        </svg>
        Searching for addresses…
      </li>
    `
    this.dropdownTarget.classList.remove("hidden")
  }

  _showHint(message) {
    this.dropdownTarget.innerHTML = `
      <li class="px-4 py-3 text-sm text-gray-400 italic">${this._esc(message)}</li>
    `
    this.dropdownTarget.classList.remove("hidden")
  }

  _hideDropdown() {
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.innerHTML = ""
  }

  _closeOnOutsideClick(e) {
    if (!this.element.contains(e.target)) this._hideDropdown()
  }

  _esc(str) {
    return String(str)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }
}
