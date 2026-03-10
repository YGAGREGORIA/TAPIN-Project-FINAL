class CreateDeals < ActiveRecord::Migration[8.1]
  def change
    create_table :deals do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :name
      t.string :deal_type
      t.integer :discount_percent
      t.string :trigger_condition
      t.integer :usage_limit
      t.integer :expiry_days
      t.boolean :active

      t.timestamps
    end
  end
end
