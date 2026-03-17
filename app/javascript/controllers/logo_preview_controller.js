import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder"]

  preview() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.classList.remove("d-none")
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.add("d-none")
      }
    }
    reader.readAsDataURL(file)
  }
}
