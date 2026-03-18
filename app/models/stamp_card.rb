class StampCard < ApplicationRecord
  belongs_to :user
  belongs_to :reward
  belongs_to :studio

  validates :status, inclusion: { in: %w[active completed redeemed] }
  validates :reward_id, uniqueness: { scope: [:user_id, :status], message: "already has an active card" },
            if: -> { active? }

  scope :active, -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }
  scope :redeemed, -> { where(status: "redeemed") }

  def active?
    status == "active"
  end

  def completed?
    status == "completed"
  end

  def redeemed?
    status == "redeemed"
  end

  def full?
    stamps_collected >= (reward.visits_required || 10)
  end

  # Add a stamp and mark completed if full
  def add_stamp!
    return unless active?

    increment!(:stamps_collected)
    if full?
      update!(status: "completed", completed_at: Time.current)
    end
  end

  def redeem!
    return unless completed?

    redemption = RewardRedemption.create!(
      user: user,
      reward: reward,
      studio: studio
    )
    update!(status: "redeemed", redeemed_at: Time.current)
    redemption
  end
end
