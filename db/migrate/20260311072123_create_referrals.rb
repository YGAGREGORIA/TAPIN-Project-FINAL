class CreateReferrals < ActiveRecord::Migration[8.1]
  def change
    create_table :referrals do |t|
      t.references :referrer, null: false, foreign_key: { to_table: :users }
      t.references :referred, null: true, foreign_key: { to_table: :users }
      t.string :referral_code, null: false
      t.string :status, default: "pending"
      t.datetime :completed_at

      t.timestamps
    end

    add_index :referrals, :referral_code, unique: true
  end
end
