class Reward < ApplicationRecord
  belongs_to :studio

  has_many :reward_redemptions, dependent: :destroy
end
