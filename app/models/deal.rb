class Deal < ApplicationRecord
  belongs_to :studio

  has_many :deal_claims, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
