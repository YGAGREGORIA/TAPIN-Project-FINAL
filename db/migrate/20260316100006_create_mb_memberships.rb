class CreateMbMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :mb_memberships do |t|
      t.string   :mb_membership_id, null: false
      t.references :mb_client, null: false, foreign_key: true
      t.string   :name, null: false
      t.decimal  :payment_amount, precision: 10, scale: 2
      t.integer  :remaining_sessions
      t.date     :active_date
      t.date     :expiration_date
      t.string   :status, default: "Active"
      t.string   :mb_site_id, null: false

      t.timestamps
    end

    add_index :mb_memberships, [:mb_site_id, :mb_membership_id], unique: true
  end
end
