class SendPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    notification = Notification.find(notification_id)
    user = notification.user
    config = Rails.application.config.webpush

    payload = {
      title: notification.title,
      options: {
        body: notification.body,
        icon: "/icon.png",
        badge: "/icon.png",
        data: { path: notification.path }
      }
    }.to_json

    user.push_subscriptions.find_each do |sub|
      WebPush.payload_send(
        message: payload,
        endpoint: sub.endpoint,
        p256dh: sub.p256dh_key,
        auth: sub.auth_key,
        vapid: {
          public_key: config[:vapid_public_key],
          private_key: config[:vapid_private_key],
          subject: config[:vapid_subject]
        }
      )
    rescue WebPush::ExpiredSubscription
      sub.destroy
    rescue WebPush::Error => e
      Rails.logger.warn("Push notification failed for subscription #{sub.id}: #{e.message}")
    end

    notification.update!(sent_at: Time.current)
  end
end
