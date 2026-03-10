class CreateDealClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :deal_claims do |t|
      t.references :user, null: false, foreign_key: true
      t.references :deal, null: false, foreign_key: true
      t.string :code
      t.boolean :status
      t.datetime :claimed_at

      t.timestamps
    end
  end
end
