class AddPhoneNumberToUsersAndCreatePhoneLoginCodes < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_number, :string
    add_index :users, :phone_number, unique: true

    create_table :phone_login_codes do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :phone_number, null: false
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.integer :attempts_count, null: false, default: 0
      t.datetime :consumed_at

      t.timestamps
    end

    add_index :phone_login_codes, [ :studio_id, :phone_number ]
  end
end
