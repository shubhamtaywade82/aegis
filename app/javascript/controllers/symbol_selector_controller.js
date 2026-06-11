import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  change(event) {
    const symbol = event.target.value
    const url = new URL(window.location.href)
    url.searchParams.set("symbol", symbol)

    // Remove turbo cache to ensure fresh data
    url.searchParams.set("_turbo_cache", Date.now())

    window.location.href = url.toString()
  }
}