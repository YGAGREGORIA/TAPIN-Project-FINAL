class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :studio

  scope :unread, -> { where(read_at: nil) }
  scope :unsent, -> { where(sent_at: nil) }

  TYPES = %w[
    reward_close
    reward_unlocked
    booking_reminder
    deal_expiry
    re_engagement
  ].freeze

  validates :notification_type, inclusion: { in: TYPES }
  validates :title, presence: true
  validates :body, presence: true
end
