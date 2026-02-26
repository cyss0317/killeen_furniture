import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["file", "button", "status", "imagePicker", "imageGrid", "scrapeStatus", "urlInput"]

  analyze() {
    const file = this.fileTarget.files[0]
    if (!file) {
      this.statusTarget.textContent = "Please select a screenshot first."
      return
    }

    const formData = new FormData()
    formData.append("screenshot", file)

    this.buttonTarget.disabled = true
    this.statusTarget.textContent = "Analyzing screenshot…"

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch("/admin/products/import_screenshot", {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken },
      body: formData
    })
      .then(res => res.json())
      .then(json => {
        if (json.error) {
          this.statusTarget.textContent = "Error: " + json.error
          this.buttonTarget.disabled = false
          return
        }
        this.fillForm(json.data)
        this.statusTarget.textContent = "✓ Form filled — please review and adjust before saving."
        this.buttonTarget.disabled = false

        // Show image picker so the URL input is immediately available
        if (this.hasImagePickerTarget) {
          this.imagePickerTarget.classList.remove("hidden")
        }

        // Automatically scrape vendor website for images using extracted SKU + brand
        if (json.data.sku && json.data.brand) {
          this.scrapeVendor(json.data.sku, json.data.brand)
        }
      })
      .catch(err => {
        this.statusTarget.textContent = "Request failed: " + err.message
        this.buttonTarget.disabled = false
      })
  }

  scrapeVendor(sku, brand) {
    if (this.hasScrapeStatusTarget) {
      this.scrapeStatusTarget.textContent = "Fetching images from vendor website…"
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const body = new FormData()
    body.append("sku", sku)
    body.append("brand", brand)

    fetch("/admin/products/scrape_vendor", {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken },
      body
    })
      .then(res => res.json())
      .then(json => {
        if (json.error) {
          if (this.hasScrapeStatusTarget) {
            this.scrapeStatusTarget.textContent = "Could not fetch vendor images: " + json.error
          }
          return
        }
        if (!json.image_urls?.length) {
          if (this.hasScrapeStatusTarget) {
            this.scrapeStatusTarget.textContent = "No images found on vendor website."
          }
          return
        }
        this.renderImagePicker(json.image_urls)
        if (this.hasScrapeStatusTarget) {
          this.scrapeStatusTarget.textContent = json.warning ? "⚠ " + json.warning : ""
        }
      })
      .catch(err => {
        if (this.hasScrapeStatusTarget) {
          this.scrapeStatusTarget.textContent = "Image fetch failed: " + err.message
        }
      })
  }

  renderImagePicker(imageUrls) {
    if (!this.hasImageGridTarget) return

    this.imageGridTarget.innerHTML = ""

    imageUrls.forEach((url, i) => {
      const label = document.createElement("label")
      label.className = "relative cursor-pointer"
      label.innerHTML = `
        <input type="checkbox" class="sr-only peer" value="${url}" data-action="change->product-import#toggleImage" checked>
        <div class="aspect-square bg-gray-100 rounded-md overflow-hidden border-2 border-transparent peer-checked:border-amber-500 transition-all">
          <img src="${url}" alt="Product image ${i + 1}" class="w-full h-full object-cover" loading="lazy"
               onerror="this.closest('label').remove(); this.getRootNode().host?.application?.getControllerForElementAndIdentifier(this.closest('[data-controller]'), 'product-import')?.syncHiddenInputs()">
        </div>
        <div class="absolute top-1 right-1 w-4 h-4 bg-amber-500 rounded-full hidden peer-checked:flex items-center justify-center pointer-events-none">
          <svg class="w-2.5 h-2.5 text-white" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
        </div>
      `
      this.imageGridTarget.appendChild(label)
    })

    // Inject hidden inputs for all checked (pre-selected) images
    this.syncHiddenInputs()
  }

  toggleImage() {
    this.syncHiddenInputs()
  }

  syncHiddenInputs() {
    const form = document.querySelector("form[data-product-form]")
    if (!form) return

    // Remove all existing vendor image URL inputs
    form.querySelectorAll('[name="product[vendor_image_urls][]"]').forEach(el => el.remove())

    // Re-add one hidden input per checked image
    if (this.hasImageGridTarget) {
      this.imageGridTarget.querySelectorAll('input[type="checkbox"]:checked').forEach(checkbox => {
        const input = document.createElement("input")
        input.type  = "hidden"
        input.name  = "product[vendor_image_urls][]"
        input.value = checkbox.value
        form.appendChild(input)
      })
    }
  }

  selectAllImages() {
    if (!this.hasImageGridTarget) return
    this.imageGridTarget.querySelectorAll('input[type="checkbox"]').forEach(cb => { cb.checked = true })
    this.syncHiddenInputs()
  }

  deselectAllImages() {
    if (!this.hasImageGridTarget) return
    this.imageGridTarget.querySelectorAll('input[type="checkbox"]').forEach(cb => { cb.checked = false })
    this.syncHiddenInputs()
  }

  addUrlImages() {
    if (!this.hasUrlInputTarget || !this.hasImageGridTarget) return

    const existing = new Set(
      [...this.imageGridTarget.querySelectorAll('input[type="checkbox"]')].map(cb => cb.value)
    )

    const urls = this.urlInputTarget.value
      .split("\n")
      .map(u => u.trim())
      .filter(u => u.match(/^https?:\/\//) && !existing.has(u))

    if (!urls.length) return

    urls.forEach((url, i) => {
      const label = document.createElement("label")
      label.className = "relative cursor-pointer"
      label.innerHTML = `
        <input type="checkbox" class="sr-only peer" value="${url}" data-action="change->product-import#toggleImage" checked>
        <div class="aspect-square bg-gray-100 rounded-md overflow-hidden border-2 border-transparent peer-checked:border-amber-500 transition-all">
          <img src="${url}" alt="Image ${i + 1}" class="w-full h-full object-cover" loading="lazy">
        </div>
        <div class="absolute top-1 right-1 w-4 h-4 bg-amber-500 rounded-full hidden peer-checked:flex items-center justify-center pointer-events-none">
          <svg class="w-2.5 h-2.5 text-white" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
        </div>
      `
      this.imageGridTarget.appendChild(label)
    })

    this.urlInputTarget.value = ""
    this.syncHiddenInputs()
  }

  fillForm(data) {
    this.setField("product_name",              data.name)
    this.setField("product_brand",             data.brand)
    this.setField("product_sku",               data.sku)
    this.setField("product_short_description", data.short_description)
    this.setField("product_color",             data.color)
    this.setField("product_material",          data.material)
    this.setField("product_weight",            data.weight)
    this.setField("product_base_cost",         data.base_cost)
    this.setField("product_dimensions_width",  data.dimensions_width)
    this.setField("product_dimensions_height", data.dimensions_height)
    this.setField("product_dimensions_depth",  data.dimensions_depth)

    // ActionText / Trix rich text editor
    if (data.description) {
      const trix = document.querySelector("trix-editor")
      if (trix) {
        trix.editor.loadHTML("<p>" + data.description.replace(/\n/g, "<br>") + "</p>")
      }
    }
  }

  setField(id, value) {
    if (value == null) return
    const el = document.getElementById(id)
    if (el) el.value = value
  }
}
