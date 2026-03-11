class MindbodyClient < ApplicationRecord
  belongs_to :studio

  validates :mindbody_client_id, presence: true, uniqueness: { scope: :studio_id }
  validates :first_name, presence: true
  validates :last_name, presence: true

  scope :by_phone, ->(phone) { where(phone: phone) }
  scope :by_name, ->(first, last) { where("LOWER(first_name) = ? AND LOWER(last_name) = ?", first.downcase, last.downcase) }
end
