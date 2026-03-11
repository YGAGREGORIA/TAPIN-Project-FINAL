# VAPID keys for Web Push notifications
# In production, set these via environment variables
Rails.application.config.webpush = {
  vapid_public_key: ENV.fetch("VAPID_PUBLIC_KEY", "BLwCAEb_BAgx1nDAtk10TMShWRx2keOC8qhVJDut1NpgDj6VhXFjfSQdLqugkudL8tCHPmEevJxdO8ZddgY_eBA="),
  vapid_private_key: ENV.fetch("VAPID_PRIVATE_KEY", "cDrRr16T0rgcNtccK4kcdUq7_ohglZTd8HFfwYSuSZk="),
  vapid_subject: ENV.fetch("VAPID_SUBJECT", "mailto:admin@tapin.app")
}
