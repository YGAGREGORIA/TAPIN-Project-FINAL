class Mb::Staff < ApplicationRecord
  self.table_name = "mb_staff"

  has_many :klasses, class_name: "Mb::Klass", foreign_key: :mb_staff_id, dependent: :destroy

  validates :mb_staff_id, presence: true, uniqueness: { scope: :mb_site_id }
  validates :first_name, :last_name, :mb_site_id, presence: true
end
