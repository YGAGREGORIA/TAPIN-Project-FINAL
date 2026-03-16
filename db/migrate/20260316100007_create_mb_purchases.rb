class CreateMbPurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :mb_purchases do |t|
      t.string   :mb_purchase_id, null: false
      t.references :mb_client, null: false, foreign_key: true
      t.string   :description
      t.decimal  :amount, precision: 10, scale: 2
      t.string   :payment_method
      t.datetime :sale_date
      t.string   :mb_site_id, null: false

      t.timestamps
    end

    add_index :mb_purchases, [:mb_site_id, :mb_purchase_id], unique: true
  end
end
