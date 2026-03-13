class CheckNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    check_close_to_reward
    check_booking_reminders
    check_deal_expiry
    check_re_engagement
  end

  private

  # Story: "I receive a notification when I'm close to a reward"
  # Triggers when user is 1-2 visits away from a milestone
  def check_close_to_reward
    Studio.find_each do |studio|
      User.joins(:visits).where(visits: { studio_id: studio.id }).distinct.find_each do |user|
        remaining = user.visits_remaining_for_next_reward(studio)
        next unless remaining.between?(1, 2)
        next if already_notified?(user, studio, "reward_close", 7.days.ago)

        create_and_send(user, studio,
          notification_type: "reward_close",
          title: "You're almost there!",
          body: "Just #{remaining} more #{remaining == 1 ? 'visit' : 'visits'} until your free class at #{studio.name}!",
          path: "/s/#{studio.slug}/rewards"
        )
      end
    end
  end

  # Story: "I receive a reminder before my booked class"
  # Push 2 hours before class time
  def check_booking_reminders
    window_start = 2.hours.from_now
    window_end = window_start + 15.minutes

    Booking.where(status: true, class_time: window_start..window_end).find_each do |booking|
      next if already_notified?(booking.user, booking.studio, "booking_reminder", 3.hours.ago)

      create_and_send(booking.user, booking.studio,
        notification_type: "booking_reminder",
        title: "Class in 2 hours",
        body: "#{booking.class_name} starts at #{booking.class_time.strftime('%-I:%M %p')}. See you there!",
        path: "/s/#{booking.studio.slug}/bookings/#{booking.id}"
      )
    end
  end

  # Story: "I receive a notification when a deal is about to expire"
  # 3 days before deal claim expiry
  def check_deal_expiry
    DealClaim.where(status: true).includes(:deal, :user, :studio).find_each do |claim|
      next unless claim.deal&.expiry_days
      expires_at = claim.claimed_at + claim.deal.expiry_days.days
      days_left = (expires_at.to_date - Date.current).to_i
      next unless days_left == 3
      next if already_notified?(claim.user, claim.studio, "deal_expiry", 1.day.ago)

      create_and_send(claim.user, claim.studio,
        notification_type: "deal_expiry",
        title: "Deal expiring soon",
        body: "Your #{claim.deal.name} deal expires in 3 days. Use code #{claim.code} before it's gone!",
        path: "/s/#{claim.studio.slug}/deal_claims/#{claim.id}"
      )
    end
  end

  # Story: "I receive a re-engagement message after 14 days of inactivity"
  def check_re_engagement
    cutoff = 14.days.ago

    User.where("last_visit_at < ? AND last_visit_at IS NOT NULL", cutoff).find_each do |user|
      user.visits.select(:studio_id).distinct.each do |visit|
        studio = Studio.find(visit.studio_id)
        next if already_notified?(user, studio, "re_engagement", 30.days.ago)

        create_and_send(user, studio,
          notification_type: "re_engagement",
          title: "We miss you!",
          body: "It's been a while since your last visit to #{studio.name}. Come back and keep earning rewards!",
          path: "/s/#{studio.slug}"
        )
      end
    end
  end

  def already_notified?(user, studio, type, since)
    Notification.where(user: user, studio: studio, notification_type: type)
                .where("created_at > ?", since)
                .exists?
  end

  def create_and_send(user, studio, notification_type:, title:, body:, path:)
    notification = Notification.create!(
      user: user,
      studio: studio,
      notification_type: notification_type,
      title: title,
      body: body,
      path: path
    )
    SendPushNotificationJob.perform_later(notification.id)
  end
end
