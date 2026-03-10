class AddStudioToDealClaims < ActiveRecord::Migration[8.1]
  def change
    add_reference :deal_claims, :studio, null: false, foreign_key: true
  end
end
