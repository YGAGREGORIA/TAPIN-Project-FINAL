class DealClaim < ApplicationRecord
  belongs_to :user
  belongs_to :deal
  belongs_to :studio

  validates :code, presence: true, uniqueness: true

  before_validation :set_defaults, on: :create

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
