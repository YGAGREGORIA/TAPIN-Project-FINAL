import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pointsValue"]

  connect() {
    this.animateSections()
    this.animatePoints()
    this.animateProgressBars()
    this.animateStamps()
  }

  animateSections() {
    const sections = this.element.querySelectorAll(".dashboard-hero, .dashboard-section")
    sections.forEach((el, i) => {
      el.style.animationDelay = `${i * 0.08}s`
      el.classList.add("animate-fade-up")
    })
  }

  animatePoints() {
    if (!this.hasPointsValueTarget) return
    const el = this.pointsValueTarget
    const target = parseInt(el.dataset.points, 10) || 0
    if (target === 0) return

    const duration = 900
    const start = performance.now()

    const tick = (now) => {
      const progress = Math.min((now - start) / duration, 1)
      const eased = 1 - Math.pow(1 - progress, 3)
      el.textContent = `${Math.round(target * eased)} pts`
      if (progress < 1) requestAnimationFrame(tick)
    }

    el.textContent = "0 pts"
    requestAnimationFrame(tick)
  }

  animateProgressBars() {
    this.element.querySelectorAll(".progress-bar").forEach(bar => {
      const targetWidth = bar.style.width
      bar.style.width = "0%"
      // slight delay so the section fade-in plays first
      setTimeout(() => { bar.style.width = targetWidth }, 400)
    })
  }

  animateStamps() {
    this.element.querySelectorAll(".stamp-grid").forEach(grid => {
      grid.querySelectorAll(".stamp").forEach((stamp, i) => {
        stamp.style.animationDelay = `${0.25 + i * 0.055}s`
        stamp.classList.add("animate-stamp")
      })
    })
  }
}
