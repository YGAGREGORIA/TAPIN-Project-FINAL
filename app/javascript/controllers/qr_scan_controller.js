import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["confettiContainer"]
  static values = { active: Boolean }

  connect() {
    if (this.activeValue) {
      this.show()
    }
  }

  show() {
    this.element.classList.add("qr-scan-overlay--visible")
    this._spawnConfetti()
  }

  dismiss() {
    this.element.classList.remove("qr-scan-overlay--visible")
  }

  _spawnConfetti() {
    const container = this.confettiContainerTarget
    // Clear any existing dots
    container.querySelectorAll(".confetti-dot").forEach(d => d.remove())

    for (let i = 1; i <= 5; i++) {
      const dot = document.createElement("span")
      dot.className = `confetti-dot confetti-dot--${i}`
      container.appendChild(dot)
    }

    // Re-trigger for looping feel — spawn a second wave after first finishes
    setTimeout(() => {
      container.querySelectorAll(".confetti-dot").forEach(d => d.remove())
      for (let i = 1; i <= 5; i++) {
        const dot = document.createElement("span")
        dot.className = `confetti-dot confetti-dot--${i}`
        container.appendChild(dot)
      }
    }, 900)
  }
}
