import { Controller } from "@hotwired/stimulus"

// Handles referral link sharing: copy to clipboard + native Web Share API
export default class extends Controller {
  static targets = ["urlField"]
  static values = { url: String, title: String, text: String }

  copy() {
    navigator.clipboard.writeText(this.urlValue).then(() => {
      const btn = this.element.querySelector("[data-action='click->share#copy']")
      const original = btn.textContent
      btn.textContent = "Copied!"
      setTimeout(() => { btn.textContent = original }, 2000)
    })
  }

  nativeShare() {
    if (navigator.share) {
      navigator.share({
        title: this.titleValue,
        text: this.textValue,
        url: this.urlValue
      }).catch(() => {
        // User cancelled share — do nothing
      })
    } else {
      // Fallback: just copy
      this.copy()
    }
  }
}
