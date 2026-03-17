class CreateStampCards < ActiveRecord::Migration[8.1]
  def change
    create_table :stamp_cards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reward, null: false, foreign_key: true
      t.references :studio, null: false, foreign_key: true
      t.integer :stamps_collected, default: 0, null: false
      t.string :status, default: "active", null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :redeemed_at

      t.timestamps
    end
  end
end
