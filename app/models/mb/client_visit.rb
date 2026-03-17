class Mb::ClientVisit < ApplicationRecord
  self.table_name = "mb_client_visits"

  belongs_to :client, class_name: "Mb::Client", foreign_key: :mb_client_id
  belongs_to :klass, class_name: "Mb::Klass", foreign_key: :mb_class_id

  validates :mb_visit_id, presence: true, uniqueness: { scope: :mb_site_id }
  validates :mb_site_id, presence: true
  validates :visit_type, inclusion: { in: %w[class appointment] }
end
