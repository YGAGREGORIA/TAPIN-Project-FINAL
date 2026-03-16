class RenameStatusToActiveOnDealClaims < ActiveRecord::Migration[8.1]
  def change
    rename_column :deal_claims, :status, :active
  end
end
