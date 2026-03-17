class Reward < ApplicationRecord
  belongs_to :studio
  has_many :reward_redemptions, dependent: :destroy
  has_many :stamp_cards, dependent: :destroy

  enum :reward_type, { free_class: 0 }

  validates :name, presence: true

  scope :active, -> { where(active: true) }

  def redeemable_by?(user)
    return false unless user

    threshold = visits_required || 10
    user_visits = user.visits_count_for(studio)
    milestones = user_visits / threshold
    redemptions = user.reward_redemptions.where(reward: self).count
    milestones > redemptions
  end
end
