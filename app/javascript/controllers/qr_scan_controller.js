import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["confettiContainer"]
  static values = { active: Boolean, code: String }

  connect() {
    if (this.activeValue) {
      this.show()
    }

    if (this.codeValue) {
      this._subscribeToChannel()
    }
  }

  disconnect() {
    if (this._subscription) {
      this._subscription.unsubscribe()
    }
  }

  _subscribeToChannel() {
    this._subscription = cable.subscribeTo(
      { channel: "RewardRedemptionChannel", code: this.codeValue },
      {
        received: (data) => {
          if (data.event === "scanned") {
            this.show()
          }
        }
      }
    )
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
    container.querySelectorAll(".confetti-dot").forEach(d => d.remove())

    for (let i = 1; i <= 5; i++) {
      const dot = document.createElement("span")
      dot.className = `confetti-dot confetti-dot--${i}`
      container.appendChild(dot)
    }

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
