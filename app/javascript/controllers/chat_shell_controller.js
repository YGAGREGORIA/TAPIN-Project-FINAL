import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "sendBtn", "suggestions", "welcome", "overlay", "sidebar", "chatTitle"]
  static values = { chatId: Number }

  connect() {
    this.scrollToBottom()
  }

  async send(event) {
    event.preventDefault()
    const message = this.inputTarget.value.trim()
    if (message === "") return

    this.appendUserMessage(message)
    this.inputTarget.value = ""
    this.appendTyping()
    this.disableInput()
    this.hideWelcome()

    await this.postMessage(message)
  }

  async sendSuggestion(event) {
    event.preventDefault()
    const message = event.currentTarget.dataset.message
    if (!message) return

    this.appendUserMessage(message)
    this.appendTyping()
    this.disableInput()
    this.hideWelcome()

    await this.postMessage(message)
  }

  async postMessage(message) {
    try {
      const formData = new FormData()
      formData.append("message", message)

      const response = await fetch(`/chats/${this.chatIdValue}/messages`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
          "Accept": "application/json"
        },
        body: formData
      })

      if (!response.ok) throw new Error("Request failed")

      const data = await response.json()
      this.removeTyping()
      this.appendAssistantMessage(data.assistant)

      if (data.title && this.hasChatTitleTarget) {
        this.chatTitleTarget.textContent = data.title
      }
    } catch (error) {
      this.removeTyping()
      this.appendAssistantMessage("Sorry, something went wrong. Please try again.")
    } finally {
      this.enableInput()
    }
  }

  appendUserMessage(text) {
    const html = `
      <div class="chat-row chat-row--user">
        <div class="chat-bubble chat-bubble--user">${this.escapeHtml(text)}</div>
        <div class="chat-avatar chat-avatar--user">You</div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  appendAssistantMessage(text) {
    const formatted = this.escapeHtml(text).replace(/\n/g, "<br>")
    const html = `
      <div class="chat-row chat-row--assistant">
        <div class="chat-avatar chat-avatar--ai">AI</div>
        <div class="chat-bubble chat-bubble--assistant">${formatted}</div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  appendTyping() {
    const html = `
      <div class="chat-row chat-row--assistant" id="typing-indicator">
        <div class="chat-avatar chat-avatar--ai">AI</div>
        <div class="typing-indicator">
          <span class="dot"></span>
          <span class="dot"></span>
          <span class="dot"></span>
        </div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  removeTyping() {
    const el = document.getElementById("typing-indicator")
    if (el) el.remove()
  }

  hideWelcome() {
    if (this.hasWelcomeTarget) this.welcomeTarget.remove()
    if (this.hasSuggestionsTarget) this.suggestionsTarget.remove()
  }

  disableInput() {
    this.inputTarget.disabled = true
    if (this.hasSendBtnTarget) this.sendBtnTarget.disabled = true
  }

  enableInput() {
    this.inputTarget.disabled = false
    if (this.hasSendBtnTarget) this.sendBtnTarget.disabled = false
    this.inputTarget.focus()
  }

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    })
  }

  openSidebar() {
    if (this.hasSidebarTarget) this.sidebarTarget.classList.add("chat-sidebar-open")
    if (this.hasOverlayTarget) this.overlayTarget.style.display = "block"
  }

  closeSidebar() {
    if (this.hasSidebarTarget) this.sidebarTarget.classList.remove("chat-sidebar-open")
    if (this.hasOverlayTarget) this.overlayTarget.style.display = "none"
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
