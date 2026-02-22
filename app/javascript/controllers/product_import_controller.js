import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["file", "button", "status"]

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
      })
      .catch(err => {
        this.statusTarget.textContent = "Request failed: " + err.message
        this.buttonTarget.disabled = false
      })
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
