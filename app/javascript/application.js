// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Reload inventory-sensitive pages when restored from the browser's bfcache.
// (pageshow fires on bfcache restore; event.persisted distinguishes it from a normal load)
window.addEventListener("pageshow", (event) => {
  if (event.persisted && document.querySelector('meta[name="turbo-cache-control"][content="no-store"]')) {
    window.location.reload()
  }
})

import "trix"
import "@rails/actiontext"
