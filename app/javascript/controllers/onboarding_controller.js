import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitBtn"]

  submit(event) {
    const btn = this.submitBtnTarget
    btn.disabled = true
    btn.innerHTML = '<span class="onboarding-spinner"></span> Processing...'
  }
}
