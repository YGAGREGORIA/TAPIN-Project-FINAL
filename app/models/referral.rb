class Referral < ApplicationRecord
  belongs_to :referrer, class_name: "User"
  belongs_to :referred, class_name: "User", optional: true

  validates :referral_code, presence: true, uniqueness: true
  validate :max_active_referrals, on: :create

  before_validation :generate_referral_code, on: :create

  scope :active, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }

  def complete!(referred_user)
    update!(
      referred: referred_user,
      status: "completed",
      completed_at: Time.current
    )
  end

  def expired?
    status == "expired"
  end

  private

  def generate_referral_code
    self.referral_code ||= loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless Referral.exists?(referral_code: code)
    end
  end

  def max_active_referrals
    return unless referrer

    if referrer.referrals.active.count >= 5
      errors.add(:base, "You can only have 5 active referral codes at a time.")
    end
  end
end
