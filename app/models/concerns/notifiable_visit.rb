module NotifiableVisit
  extend ActiveSupport::Concern

  included do
    after_create :notify_reward_unlocked
  end

  private

  # Story: "I receive a notification when I unlock a new reward"
  def notify_reward_unlocked
    return unless user.free_class_reward_available_for?(studio)

    # Only notify if this visit is the one that crossed the milestone
    return unless (user.visits_count_for(studio) % 10).zero?

    notification = Notification.create!(
      user: user,
      studio: studio,
      notification_type: "reward_unlocked",
      title: "Reward unlocked!",
      body: "You've earned a free class at #{studio.name}! Redeem it now.",
      path: "/s/#{studio.slug}/rewards"
    )
    SendPushNotificationJob.perform_later(notification.id)
  end
end
