import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "sendBtn", "suggestions", "welcome", "overlay", "sidebar", "chatTitle", "imageInput", "imagePreview"]
  static values = { chatId: Number }

  connect() {
    this.scrollToBottom()
  }

  async send(event) {
    event.preventDefault()
    const message = this.inputTarget.value.trim()
    const imageFile = this.hasImageInputTarget ? this.imageInputTarget.files[0] : null

    if (message === "" && !imageFile) return

    this.appendUserMessage(message, imageFile)
    this.inputTarget.value = ""
    if (this.hasImageInputTarget) this.imageInputTarget.value = ""
    this.clearImagePreview()
    this.appendTyping()
    this.disableInput()
    this.hideWelcome()

    await this.postMessage(message, imageFile)
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

  async postMessage(message, imageFile = null) {
    try {
      const formData = new FormData()
      formData.append("message", message)
      formData.append("stream", "true")
      if (imageFile) formData.append("image", imageFile)

      const response = await fetch(`/chats/${this.chatIdValue}/messages`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: formData
      })

      if (!response.ok) throw new Error("Request failed")

      const contentType = response.headers.get("content-type") || ""

      if (contentType.includes("text/event-stream")) {
        await this.handleStream(response)
      } else {
        // Fallback to JSON response
        const data = await response.json()
        this.removeTyping()
        this.appendAssistantMessage(data.assistant)
        if (data.title && this.hasChatTitleTarget) {
          this.chatTitleTarget.textContent = data.title
        }
      }
    } catch (error) {
      this.removeTyping()
      this.appendAssistantMessage("Sorry, something went wrong. Please try again.")
    } finally {
      this.enableInput()
    }
  }

  async handleStream(response) {
    const reader = response.body.getReader()
    const decoder = new TextDecoder()
    let buffer = ""
    let assistantBubble = null
    let fullText = ""

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })
      const lines = buffer.split("\n")
      buffer = lines.pop() // keep incomplete line in buffer

      for (const line of lines) {
        if (!line.startsWith("data: ")) continue

        try {
          const data = JSON.parse(line.slice(6))

          if (data.type === "title" && this.hasChatTitleTarget) {
            this.chatTitleTarget.textContent = data.title
          } else if (data.type === "chunk") {
            if (!assistantBubble) {
              this.removeTyping()
              assistantBubble = this.createStreamingBubble()
            }
            fullText += data.content
            this.updateStreamingBubble(assistantBubble, fullText)
            this.scrollToBottom()
          } else if (data.type === "done") {
            if (assistantBubble) {
              this.updateStreamingBubble(assistantBubble, fullText)
            }
          } else if (data.type === "error") {
            this.removeTyping()
            if (!assistantBubble) {
              this.appendAssistantMessage(data.content)
            } else {
              this.updateStreamingBubble(assistantBubble, data.content)
            }
          }
        } catch (e) {
          // skip malformed SSE data
        }
      }
    }

    // If we never got any chunks, remove typing
    if (!assistantBubble) {
      this.removeTyping()
    }
  }

  createStreamingBubble() {
    const html = `
      <div class="chat-row chat-row--assistant">
        <div class="chat-avatar chat-avatar--ai">AI</div>
        <div class="chat-bubble chat-bubble--assistant chat-bubble--streaming"></div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    return this.messagesTarget.querySelector(".chat-bubble--streaming")
  }

  updateStreamingBubble(bubble, text) {
    bubble.innerHTML = this.renderMarkdown(text)
  }

  // Image handling
  triggerImageUpload() {
    if (this.hasImageInputTarget) this.imageInputTarget.click()
  }

  previewImage() {
    if (!this.hasImageInputTarget) return
    const file = this.imageInputTarget.files[0]
    if (!file) return

    if (!this.hasImagePreviewTarget) return
    const reader = new FileReader()
    reader.onload = (e) => {
      this.imagePreviewTarget.innerHTML = `
        <div class="image-preview">
          <img src="${e.target.result}" alt="Upload preview">
          <button type="button" class="image-preview__remove" data-action="click->chat-shell#removeImage">&times;</button>
        </div>`
      this.imagePreviewTarget.style.display = "block"
    }
    reader.readAsDataURL(file)
  }

  removeImage() {
    if (this.hasImageInputTarget) this.imageInputTarget.value = ""
    this.clearImagePreview()
  }

  clearImagePreview() {
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.innerHTML = ""
      this.imagePreviewTarget.style.display = "none"
    }
  }

  appendUserMessage(text, imageFile = null) {
    let imageHtml = ""
    if (imageFile) {
      const url = URL.createObjectURL(imageFile)
      imageHtml = `<img src="${url}" class="chat-image" alt="Uploaded image">`
    }

    const textHtml = text ? `<span>${this.escapeHtml(text)}</span>` : ""
    const html = `
      <div class="chat-row chat-row--user">
        <div class="chat-bubble chat-bubble--user">${imageHtml}${textHtml}</div>
        <div class="chat-avatar chat-avatar--user">You</div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  appendAssistantMessage(text) {
    const html = `
      <div class="chat-row chat-row--assistant">
        <div class="chat-avatar chat-avatar--ai">AI</div>
        <div class="chat-bubble chat-bubble--assistant">${this.renderMarkdown(text)}</div>
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

  // Simple markdown renderer (no external deps)
  renderMarkdown(text) {
    let html = this.escapeHtml(text)

    // Bold: **text**
    html = html.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")

    // Italic: *text*
    html = html.replace(/\*(.+?)\*/g, "<em>$1</em>")

    // Inline code: `code`
    html = html.replace(/`(.+?)`/g, "<code>$1</code>")

    // Unordered lists: lines starting with - or *
    html = html.replace(/^[\-\*] (.+)$/gm, "<li>$1</li>")
    html = html.replace(/((?:<li>.*<\/li>\n?)+)/g, "<ul>$1</ul>")

    // Numbered lists: lines starting with 1. 2. etc
    html = html.replace(/^\d+\. (.+)$/gm, "<li>$1</li>")
    html = html.replace(/((?:<li>.*<\/li>\n?)+)/g, (match) => {
      if (!match.includes("<ul>")) return `<ol>${match}</ol>`
      return match
    })

    // Headers: ### text
    html = html.replace(/^### (.+)$/gm, "<h4>$1</h4>")
    html = html.replace(/^## (.+)$/gm, "<h3>$1</h3>")

    // Line breaks
    html = html.replace(/\n/g, "<br>")

    // Clean up extra br in lists
    html = html.replace(/<\/li><br>/g, "</li>")
    html = html.replace(/<\/ul><br>/g, "</ul>")
    html = html.replace(/<\/ol><br>/g, "</ol>")

    return html
  }
}
