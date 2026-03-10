class CreateRewardRedemptions < ActiveRecord::Migration[8.1]
  def change
    create_table :reward_redemptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reward, null: false, foreign_key: true
      t.string :code
      t.integer :point_spent
      t.boolean :status
      t.datetime :redeemed_at
      t.integer :expiry_days
      t.references :studio, null: false, foreign_key: true

      t.timestamps
    end
  end
end
