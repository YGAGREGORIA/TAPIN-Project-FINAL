class RewardRedemption < ApplicationRecord
  belongs_to :user
  belongs_to :reward
  belongs_to :studio
end
