import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitBtn", "loadingHint"]

  submit(event) {
    event.preventDefault()

    const btn = this.submitBtnTarget
    const form = event.target

    btn.disabled = true
    btn.innerHTML = '<span class="onboarding-spinner"></span> Connecting...'

    if (this.hasLoadingHintTarget) {
      this.loadingHintTarget.hidden = false
    }

    window.setTimeout(() => form.submit(), 5000)
  }
}
