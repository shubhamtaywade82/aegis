import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  change(event) {
    const symbol = event.target.value
    const url = new URL(window.location.href)
    url.searchParams.set("symbol", symbol)

    // Use Turbo.visit to navigate smoothly and update the address bar
    Turbo.visit(url.toString())
  }
}