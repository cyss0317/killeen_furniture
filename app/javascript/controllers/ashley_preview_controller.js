import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["skuInput", "lookupButton", "status", "modal", "modalContent"]

  lookup() {
    const sku = this.skuInputTarget.value.trim()
    if (!sku) {
      this.setStatus("Please enter a SKU.", "error")
      return
    }

    this.lookupButtonTarget.disabled = true
    this.setStatus("Fetching from Ashley API…", "loading")

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch("/admin/products/ashley_lookup", {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify({ sku })
    })
      .then(res => res.json().then(json => ({ ok: res.ok, json })))
      .then(({ ok, json }) => {
        this.lookupButtonTarget.disabled = false
        if (!ok || json.error) {
          this.setStatus("Error: " + (json.error || "Unknown error"), "error")
          return
        }
        this.setStatus("✓ Product found — review and confirm below.", "success")
        this.renderModal(json)
      })
      .catch(err => {
        this.lookupButtonTarget.disabled = false
        this.setStatus("Request failed: " + err.message, "error")
      })
  }

  renderModal(json) {
    const { data, image_urls, ashley_payload } = json
    const images = image_urls || []

    const imageGrid = images.length > 0
      ? `<div class="grid grid-cols-4 sm:grid-cols-6 gap-2 mb-4">
          ${images.map((url, i) => `
            <label class="relative cursor-pointer">
              <input type="checkbox" class="sr-only peer ashley-preview-image" value="${url}" checked>
              <div class="aspect-square bg-gray-100 rounded-md overflow-hidden border-2 border-transparent peer-checked:border-amber-500 transition-all">
                <img src="${url}" alt="Image ${i + 1}" class="w-full h-full object-cover" loading="lazy">
              </div>
              <div class="absolute top-1 right-1 w-4 h-4 bg-amber-500 rounded-full hidden peer-checked:flex items-center justify-center pointer-events-none">
                <svg class="w-2.5 h-2.5 text-white" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                </svg>
              </div>
            </label>
          `).join("")}
        </div>`
      : `<p class="text-sm text-gray-400 mb-4">No images found.</p>`

    const fields = [
      ["Name",              data.name],
      ["Brand",             data.brand],
      ["SKU",               data.sku],
      ["Short Description", data.short_description],
      ["Color",             data.color],
      ["Material",          data.material],
      ["Weight (lbs)",      data.weight],
      ["Base Cost ($)",     data.base_cost],
      ["Width (in)",        data.dimensions_width],
      ["Height (in)",       data.dimensions_height],
      ["Depth (in)",        data.dimensions_depth],
    ].filter(([, v]) => v != null && v !== "")

    const rows = fields.map(([label, value]) => `
      <div class="py-2 sm:grid sm:grid-cols-3 sm:gap-4">
        <dt class="text-sm font-medium text-gray-500">${label}</dt>
        <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">${value}</dd>
      </div>
    `).join("")

    this.modalContentTarget.innerHTML = `
      <div class="flex items-start justify-between mb-4">
        <div>
          <h3 class="text-lg font-semibold text-gray-900">Ashley Product Preview</h3>
          <p class="text-sm text-gray-500">Review the data below. Click <strong>Apply to Form</strong> to populate fields and select images.</p>
        </div>
        <button type="button" data-action="click->ashley-preview#closeModal"
                class="text-gray-400 hover:text-gray-700 p-1 rounded transition-colors ml-4">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>

      ${images.length > 0 ? '<h4 class="text-sm font-medium text-gray-700 mb-2">Images <span class="font-normal text-gray-400">(uncheck to skip)</span></h4>' : ""}
      ${imageGrid}

      <h4 class="text-sm font-medium text-gray-700 mb-2 mt-2">Product Fields</h4>
      <dl class="divide-y divide-gray-100 mb-6">${rows}</dl>

      <div class="flex gap-3">
        <button type="button" data-action="click->ashley-preview#applyToForm"
                data-payload='${JSON.stringify({ data, image_urls: images })}'
                class="flex-1 bg-amber-800 text-white text-sm font-semibold py-2.5 px-4 rounded-md hover:bg-amber-900 transition-colors">
          Apply to Form
        </button>
        <button type="button" data-action="click->ashley-preview#closeModal"
                class="flex-1 border border-gray-300 text-gray-700 text-sm font-medium py-2.5 px-4 rounded-md hover:bg-gray-50 transition-colors">
          Cancel
        </button>
      </div>
    `

    // Store raw payload for later
    this._rawPayload = ashley_payload

    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  applyToForm(event) {
    const btn = event.currentTarget
    let payload
    try { payload = JSON.parse(btn.dataset.payload) } catch { return }

    const { data, image_urls } = payload

    // Get checked image URLs from modal
    const checkedUrls = [...this.modalTarget.querySelectorAll(".ashley-preview-image:checked")]
      .map(cb => cb.value)

    // Fill the main product form using existing fillForm-style helper
    this._setField("product_name",              data.name)
    this._setField("product_brand",             data.brand)
    this._setField("product_sku",               data.sku)
    this._setField("product_short_description", data.short_description)
    this._setField("product_color",             data.color)
    this._setField("product_material",          data.material)
    this._setField("product_weight",            data.weight)
    this._setField("product_base_cost",         data.base_cost)
    this._setField("product_dimensions_width",  data.dimensions_width)
    this._setField("product_dimensions_height", data.dimensions_height)
    this._setField("product_dimensions_depth",  data.dimensions_depth)

    if (data.description) {
      const trix = document.querySelector("trix-editor")
      if (trix) trix.editor.loadHTML("<p>" + data.description.replace(/\n/g, "<br>") + "</p>")
    }

    // Inject chosen image URLs into the product form
    if (checkedUrls.length > 0) {
      const form = document.querySelector("form[data-product-form]")
      if (form) {
        // Remove existing vendor URL inputs first (added by product-import controller)
        form.querySelectorAll('[name="product[vendor_image_urls][]"]').forEach(el => el.remove())
        checkedUrls.forEach(url => {
          const input = document.createElement("input")
          input.type  = "hidden"
          input.name  = "product[vendor_image_urls][]"
          input.value = url
          form.appendChild(input)
        })

        // Also render a visual image picker via product-import if available
        const importCtrl = this.application.getControllerForElementAndIdentifier(
          document.querySelector('[data-controller~="product-import"]'),
          "product-import"
        )
        if (importCtrl) {
          importCtrl.renderImagePicker(checkedUrls)
          if (importCtrl.hasImagePickerTarget) importCtrl.imagePickerTarget.classList.remove("hidden")
        }
      }
    }

    this.closeModal()
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  setStatus(message, type = "info") {
    if (!this.hasStatusTarget) return
    const colors = { loading: "text-blue-600", success: "text-green-700", error: "text-red-600", info: "text-gray-500" }
    this.statusTarget.textContent = message
    this.statusTarget.className = `text-sm ${colors[type] || "text-gray-500"}`
  }

  _setField(id, value) {
    if (value == null || value === "") return
    const el = document.getElementById(id)
    if (el) el.value = value
  }
}
