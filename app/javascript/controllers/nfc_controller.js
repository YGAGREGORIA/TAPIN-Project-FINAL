import { Controller } from "@hotwired/stimulus"

// Handles Web NFC reading on Android Chrome 89+
// Falls back gracefully — QR codes work on all devices
export default class extends Controller {
  static targets = ["status"]
  static values = { studioSlug: String }

  connect() {
    if ("NDEFReader" in window) {
      this.startNfcReader()
    }
  }

  async startNfcReader() {
    try {
      const reader = new NDEFReader()
      await reader.scan()
      this.showStatus("Ready to read NFC tag...", "info")

      reader.addEventListener("reading", (event) => {
        this.handleNfcRead(event)
      })

      reader.addEventListener("readingerror", () => {
        this.showStatus("Could not read NFC tag. Try again.", "error")
      })
    } catch (error) {
      // Permission denied or NFC not available — silent fail, QR is the fallback
      console.log("NFC not available:", error.message)
    }
  }

  handleNfcRead(event) {
    const decoder = new TextDecoder()
    for (const record of event.message.records) {
      if (record.recordType === "url" || record.recordType === "text") {
        const url = decoder.decode(record.data)
        if (url.includes(`/s/${this.studioSlugValue}`)) {
          this.showStatus("NFC tag detected! Checking you in...", "success")
          // The NFC tag URL points to this page — if user is already here,
          // the page is already loaded. This confirms the tap was valid.
          window.location.reload()
        }
      }
    }
  }

  showStatus(message, type) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
    this.statusTarget.style.display = "block"
    this.statusTarget.style.backgroundColor =
      type === "success" ? "#d4edda" :
      type === "error" ? "#f8d7da" : "#d1ecf1"
  }
}
