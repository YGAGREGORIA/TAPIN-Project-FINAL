class Mb::Membership < ApplicationRecord
  self.table_name = "mb_memberships"

  belongs_to :client, class_name: "Mb::Client", foreign_key: :mb_client_id

  validates :mb_membership_id, presence: true, uniqueness: { scope: :mb_site_id }
  validates :name, :mb_site_id, presence: true
  validates :status, inclusion: { in: %w[Active Expired Suspended] }
end
