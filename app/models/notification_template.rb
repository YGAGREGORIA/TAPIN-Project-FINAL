class NotificationTemplate < ApplicationRecord
  belongs_to :studio

  VALID_EVENT_TYPES = %w[reward_unlocked deal_available booking_reminder inactive_user deal_expiry].freeze

  validates :event_type, presence: true, inclusion: { in: VALID_EVENT_TYPES }
  validates :title_template, presence: true
  validates :body_template, presence: true

  scope :enabled, -> { where(enabled: true) }
end
