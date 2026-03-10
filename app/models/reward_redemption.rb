class RewardRedemption < ApplicationRecord
  belongs_to :user
  belongs_to :reward
  belongs_to :studio

  validates :code, presence: true, uniqueness: true

  before_validation :set_defaults, on: :create

  scope :latest_first, -> { order(created_at: :desc) }

  def expires_at
    redeemed_at + expiry_days.days
  end

  def expired?
    Time.current > expires_at
  end

  private

  def set_defaults
    self.code ||= generate_code
    self.redeemed_at ||= Time.current
    self.expiry_days ||= 30
    self.point_spent ||= 0
    self.status = true if status.nil?
    self.studio ||= reward&.studio
  end

  def generate_code
    loop do
      new_code = "FREE-#{SecureRandom.alphanumeric(8).upcase}"
      break new_code unless RewardRedemption.exists?(code: new_code)
    end
  end
end
