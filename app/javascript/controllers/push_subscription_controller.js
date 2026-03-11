import { Controller } from "@hotwired/stimulus"

// Handles push notification subscription for PWA
// Requests permission, subscribes via service worker, sends subscription to server
export default class extends Controller {
  static values = { vapidPublicKey: String }

  async connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) return
    if (Notification.permission === "granted") {
      await this.subscribe()
    }
  }

  async requestPermission() {
    const permission = await Notification.requestPermission()
    if (permission === "granted") {
      await this.subscribe()
    }
  }

  async subscribe() {
    try {
      const registration = await navigator.serviceWorker.ready
      const existing = await registration.pushManager.getSubscription()
      if (existing) return // Already subscribed

      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKeyValue)
      })

      await this.sendSubscriptionToServer(subscription)
    } catch (error) {
      console.log("Push subscription failed:", error.message)
    }
  }

  async sendSubscriptionToServer(subscription) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const body = {
      push_subscription: {
        endpoint: subscription.endpoint,
        p256dh_key: btoa(String.fromCharCode(...new Uint8Array(subscription.getKey("p256dh")))),
        auth_key: btoa(String.fromCharCode(...new Uint8Array(subscription.getKey("auth"))))
      }
    }

    await fetch("/push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify(body)
    })
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = atob(base64)
    return Uint8Array.from([...rawData].map(char => char.charCodeAt(0)))
  }
}
