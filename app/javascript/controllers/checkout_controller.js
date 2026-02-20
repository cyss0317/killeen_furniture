import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zipCode", "submitButton"]

  connect() {
    const stripeKey = document.querySelector("meta[name='stripe-key']")?.content
    if (!stripeKey || stripeKey === "") {
      console.warn("[Checkout] Stripe publishable key not set. Payment will not work.")
      return
    }

    this.stripe   = Stripe(stripeKey)
    this.elements = this.stripe.elements()
    this.card     = this.elements.create("card", {
      style: {
        base: {
          fontSize:   "16px",
          color:      "#374151",
          fontFamily: "'Inter', ui-sans-serif, system-ui, sans-serif",
          "::placeholder": { color: "#9CA3AF" }
        },
        invalid: { color: "#DC2626" }
      }
    })
    this.card.mount("#card-element")

    this.card.on("change", (event) => {
      const errEl = document.getElementById("card-errors")
      errEl.textContent = event.error ? event.error.message : ""
    })
  }

  async calculateShipping() {
    const zip = this.zipCodeTarget.value.trim()
    const resultEl = document.getElementById("shipping-result")
    const displayEl = document.getElementById("shipping-display")

    if (zip.length < 5) {
      resultEl.textContent = ""
      return
    }

    resultEl.innerHTML = '<span class="text-gray-400">Calculating...</span>'

    try {
      const response = await fetch(`/checkout/calculate_shipping?zip_code=${encodeURIComponent(zip)}`, {
        headers: { "Accept": "application/json" }
      })
      const data = await response.json()

      if (data.success) {
        resultEl.innerHTML = `<span class="text-green-600 font-medium">Delivery available — $${parseFloat(data.cost).toFixed(2)}</span>`
        if (displayEl) displayEl.textContent = `$${parseFloat(data.cost).toFixed(2)}`
        this.shippingCost = data.cost
      } else {
        resultEl.innerHTML = `<span class="text-red-600">${data.error}</span>`
        if (displayEl) displayEl.textContent = "Not available"
        this.shippingCost = null
      }
    } catch (err) {
      resultEl.innerHTML = `<span class="text-red-600">Unable to calculate shipping. Please try again.</span>`
    }
  }

  async handleSubmit(event) {
    if (!this.stripe || !this.card) {
      document.getElementById("checkout-errors").textContent = "Payment system not available. Please refresh the page."
      document.getElementById("checkout-errors").classList.remove("hidden")
      return
    }

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Processing..."

    // Collect form data
    const form      = this.element.querySelector("form") || document.querySelector("[data-controller='checkout']")
    const formData  = this.collectFormData()

    // Validate fields
    const required = ["full_name", "email", "phone", "street_address", "city", "state", "zip_code"]
    for (const field of required) {
      if (!formData[`checkout[${field}]`]) {
        this.showError(`Please fill in the ${field.replace("_", " ")} field.`)
        return
      }
    }

    const errEl = document.getElementById("checkout-errors")
    errEl.classList.add("hidden")

    try {
      // Step 1: Create order and get client_secret from our server
      const body = new URLSearchParams(formData)
      const response = await fetch("/checkout", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
          "Accept":       "application/json"
        },
        body: body.toString()
      })

      const serverData = await response.json()

      if (!response.ok || serverData.error) {
        this.showError(serverData.error || "Unable to process order. Please try again.")
        return
      }

      // Step 2: Confirm card payment with Stripe
      const { paymentIntent, error: stripeError } = await this.stripe.confirmCardPayment(
        serverData.client_secret,
        { payment_method: { card: this.card } }
      )

      if (stripeError) {
        document.getElementById("card-errors").textContent = stripeError.message
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.textContent = "Place Order"
      } else if (paymentIntent.status === "succeeded") {
        window.location.href = "/checkout/confirmation"
      }
    } catch (err) {
      this.showError("A network error occurred. Please check your connection and try again.")
    }
  }

  collectFormData() {
    const data = {}
    const fields = ["full_name", "email", "phone", "street_address", "city", "state", "zip_code"]
    fields.forEach(field => {
      const el = this.element.querySelector(`[name="checkout[${field}]"]`)
      if (el) data[`checkout[${field}]`] = el.value
    })
    return data
  }

  showError(message) {
    const errEl = document.getElementById("checkout-errors")
    errEl.textContent = message
    errEl.classList.remove("hidden")
    errEl.scrollIntoView({ behavior: "smooth", block: "center" })
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.textContent = "Place Order"
  }
}
