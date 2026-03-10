class DealClaim < ApplicationRecord
  belongs_to :user
  belongs_to :deal
  belongs_to :studio
end
