class Mb::ClassDescription < ApplicationRecord
  self.table_name = "mb_class_descriptions"

  has_many :klasses, class_name: "Mb::Klass", foreign_key: :mb_class_description_id, dependent: :destroy

  validates :mb_class_description_id, presence: true, uniqueness: { scope: :mb_site_id }
  validates :name, :mb_site_id, presence: true
end
