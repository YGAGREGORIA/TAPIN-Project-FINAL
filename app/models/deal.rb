class Deal < ApplicationRecord
  belongs_to :studio

  has_many :deal_claims, dependent: :destroy
end
