class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
      change_table :users, bulk: true do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
