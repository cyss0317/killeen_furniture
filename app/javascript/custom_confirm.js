import { Turbo } from "@hotwired/turbo-rails"

// Intercept Turbo's default confirm dialog and use a custom <dialog> partial
// The partial should be present in the layout: `<%= render "shared/confirm_modal" %>`
Turbo.setConfirmMethod((message, element) => {
  return new Promise((resolve) => {
    const dialog = document.getElementById('turbo-confirm-modal')
    
    // Fall back to native confirm if the partial is somehow missing from layout
    if (!dialog) {
      resolve(window.confirm(message))
      return
    }

    const messageEl = dialog.querySelector('.confirm-message')
    const cancelBtn = dialog.querySelector('.confirm-cancel')
    const confirmBtn = dialog.querySelector('.confirm-accept')

    messageEl.textContent = message
    
    // <dialog> natively blocks the page, but we must remove the inert attribute to allow interactions
    dialog.removeAttribute('inert')
    dialog.showModal()

    const cleanup = () => {
      cancelBtn.removeEventListener('click', onCancel)
      confirmBtn.removeEventListener('click', onConfirm)
      dialog.close()
      dialog.setAttribute('inert', '')
    }

    const onCancel = () => { cleanup(); resolve(false) }
    const onConfirm = () => { cleanup(); resolve(true) }

    cancelBtn.addEventListener('click', onCancel)
    confirmBtn.addEventListener('click', onConfirm)
  })
})
