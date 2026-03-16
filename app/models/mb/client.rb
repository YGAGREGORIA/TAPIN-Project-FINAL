class Mb::Client < ApplicationRecord
  self.table_name = "mb_clients"

  has_many :client_visits, class_name: "Mb::ClientVisit", foreign_key: :mb_client_id, dependent: :destroy
  has_many :memberships, class_name: "Mb::Membership", foreign_key: :mb_client_id, dependent: :destroy
  has_many :purchases, class_name: "Mb::Purchase", foreign_key: :mb_client_id, dependent: :destroy

  validates :mb_client_id, presence: true, uniqueness: { scope: :mb_site_id }
  validates :first_name, :last_name, :mb_site_id, presence: true
  validates :status, inclusion: { in: %w[Active Inactive Expired] }
end
