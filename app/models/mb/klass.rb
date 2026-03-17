class Mb::Klass < ApplicationRecord
  self.table_name = "mb_classes"

  belongs_to :class_description, class_name: "Mb::ClassDescription", foreign_key: :mb_class_description_id
  belongs_to :staff, class_name: "Mb::Staff", foreign_key: :mb_staff_id

  has_many :client_visits, class_name: "Mb::ClientVisit", foreign_key: :mb_class_id, dependent: :destroy

  validates :mb_class_id, presence: true, uniqueness: { scope: :mb_site_id }
  validates :start_datetime, :end_datetime, :mb_site_id, presence: true
end
