class DealClaim < ApplicationRecord
  belongs_to :user
  belongs_to :deal
  belongs_to :studio

  validates :code, presence: true, uniqueness: true

  before_validation :set_defaults, on: :create

  scope :latest_first, -> { order(created_at: :desc) }

  def expires_at
    return nil unless claimed_at && deal&.expiry_days
    claimed_at + deal.expiry_days.days
  end

  def expired?
    return false unless expires_at
    Time.current > expires_at
  end

  private

  def set_defaults
    self.code ||= generate_code
    self.claimed_at ||= Time.current
    self.status = true if status.nil?
    self.studio ||= deal&.studio
  end

  def generate_code
    loop do
      new_code = "DEAL-#{SecureRandom.alphanumeric(8).upcase}"
      break new_code unless DealClaim.exists?(code: new_code)
    end
  end
end
