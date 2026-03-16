class Mb::Purchase < ApplicationRecord
  self.table_name = "mb_purchases"

  belongs_to :client, class_name: "Mb::Client", foreign_key: :mb_client_id

  validates :mb_purchase_id, presence: true, uniqueness: { scope: :mb_site_id }
  validates :mb_site_id, presence: true
end
