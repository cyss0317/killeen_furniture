import { Controller } from "@hotwired/stimulus"

const FIELD_ERROR_CLASSES  = ["border-red-400", "ring-2", "ring-red-200", "focus:ring-red-300"]
const FIELD_NORMAL_CLASSES = ["border-warm-400"]

// Blocks obvious bot/gibberish names and bad emails before the form reaches
// the server, saving a confirmation email send on every rejection.
export default class extends Controller {
  static targets = ["firstName", "lastName", "email",
                    "firstNameError", "lastNameError", "emailError"]

  connect() {
    this.element.addEventListener("submit", this.#validate.bind(this))

    // Clear field highlight + message as soon as the user starts correcting it
    this.#watchField(this.firstNameTarget, this.firstNameErrorTarget)
    this.#watchField(this.lastNameTarget,  this.lastNameErrorTarget)
    if (this.hasEmailTarget) {
      this.#watchField(this.emailTarget, this.emailErrorTarget)
    }
  }

  disconnect() {
    this.element.removeEventListener("submit", this.#validate.bind(this))
  }

  #validate(event) {
    const first = this.firstNameTarget.value.trim()
    const last  = this.lastNameTarget.value.trim()
    const email = this.hasEmailTarget ? this.emailTarget.value.trim() : ""

    // Reset everything before re-evaluating
    this.#clearField(this.firstNameTarget, this.firstNameErrorTarget)
    this.#clearField(this.lastNameTarget,  this.lastNameErrorTarget)
    if (this.hasEmailTarget) this.#clearField(this.emailTarget, this.emailErrorTarget)

    let hasErrors = false

    const firstError = this.#nameError(first, "First name")
    if (firstError) {
      this.#setFieldError(this.firstNameTarget, this.firstNameErrorTarget, firstError)
      hasErrors = true
    }

    const lastError = this.#nameError(last, "Last name")
    if (lastError) {
      this.#setFieldError(this.lastNameTarget, this.lastNameErrorTarget, lastError)
      hasErrors = true
    }

    // Same value in both name fields is a strong bot signal — highlight both
    if (!firstError && !lastError && first.length > 0 && last.length > 0) {
      if (first.toLowerCase() === last.toLowerCase()) {
        const msg = "First and last name cannot be the same."
        this.#setFieldError(this.firstNameTarget, this.firstNameErrorTarget, msg)
        this.#setFieldError(this.lastNameTarget,  this.lastNameErrorTarget,  msg)
        hasErrors = true
      }
    }

    if (this.hasEmailTarget) {
      const emailError = this.#emailError(email)
      if (emailError) {
        this.#setFieldError(this.emailTarget, this.emailErrorTarget, emailError)
        hasErrors = true
      }
    }

    if (hasErrors) {
      event.preventDefault()
      event.stopImmediatePropagation()

      // Scroll to the first highlighted field
      const firstInvalid = [
        this.firstNameTarget, this.lastNameTarget, this.emailTarget
      ].find(el => el.classList.contains("border-red-400"))
      firstInvalid?.scrollIntoView({ behavior: "smooth", block: "nearest" })
    }
  }

  #nameError(value, label) {
    const letters = value.toLowerCase().replace(/[^a-z]/g, "")

    if (letters.length === 0) return null // blank — let Rails handle presence validation

    // Max 14 characters
    if (value.replace(/\s/g, "").length > 14) return `${label} must be 14 characters or fewer.`

    // Must contain at least one vowel
    if (!/[aeiou]/.test(letters)) return `${label} doesn't look like a real name.`

    // No more than 3 consecutive consonants (catches "brnxqz", "dkfjhk", etc.)
    if (/[^aeiou]{4,}/.test(letters)) return `${label} doesn't look like a real name.`

    // Vowel ratio: at least 1 vowel per 5 characters (20%)
    const vowels = letters.replace(/[^aeiou]/g, "").length
    if (letters.length > 3 && vowels / letters.length < 0.20) {
      return `${label} doesn't look like a real name.`
    }

    // Can't be a single repeated character (e.g. "aaaa", "jjjj")
    if (/^(.)\1+$/.test(letters)) return `${label} doesn't look like a real name.`

    // Must be only letters, spaces, hyphens, apostrophes
    if (/[^a-zA-Z\s\-']/.test(value)) {
      return `${label} can only contain letters, hyphens, or apostrophes.`
    }

    return null
  }

  #emailError(value) {
    if (value.length === 0) return null // let Rails/Devise handle blank

    // Must have exactly one @ with something on both sides
    if (!/^[^\s@]+@[^\s@]+$/.test(value)) return "Email address doesn't look valid."

    // Domain must contain at least one dot after the @
    const domain = value.split("@")[1] || ""
    if (!domain.includes(".")) return "Email address doesn't look valid."

    // No spaces anywhere
    if (/\s/.test(value)) return "Email address cannot contain spaces."

    // Local part before @ must be at least 1 char, domain at least 3 (a.b)
    const [local] = value.split("@")
    if (local.length < 1 || domain.length < 3) return "Email address doesn't look valid."

    // Too many dots is a strong spam signal (e.g. a.b.c.d.e.f@x.com)
    if ((value.match(/\./g) || []).length > 5) return "Email address doesn't look valid."

    return null
  }

  #setFieldError(input, msgEl, message) {
    input.classList.remove(...FIELD_NORMAL_CLASSES)
    input.classList.add(...FIELD_ERROR_CLASSES)
    msgEl.textContent = message
    msgEl.classList.remove("hidden")
  }

  #clearField(input, msgEl) {
    input.classList.remove(...FIELD_ERROR_CLASSES)
    input.classList.add(...FIELD_NORMAL_CLASSES)
    msgEl.textContent = ""
    msgEl.classList.add("hidden")
  }

  #watchField(input, msgEl) {
    input.addEventListener("input", () => this.#clearField(input, msgEl))
  }
}
