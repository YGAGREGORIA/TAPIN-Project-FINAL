class Reward < ApplicationRecord
  belongs_to :studio
  has_many :reward_redemptions, dependent: :destroy

  enum :reward_type, { free_class: 0 }

  validates :name, presence: true

  scope :active, -> { where(active: true) }

  def redeemable_by?(user)
    return false unless user

    if free_class?
      user.free_class_reward_available_for?(studio)
    else
      false
    end
  end
end
