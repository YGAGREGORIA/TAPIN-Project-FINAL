class CreateMbClients < ActiveRecord::Migration[8.1]
  def change
    create_table :mb_clients do |t|
      t.string :mb_client_id, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.date   :birth_date
      t.string :gender
      t.string :status, default: "Active"
      t.datetime :creation_date
      t.string :mb_site_id, null: false

      t.timestamps
    end

    add_index :mb_clients, [:mb_site_id, :mb_client_id], unique: true
    add_index :mb_clients, [:mb_site_id, :email]
    add_index :mb_clients, [:mb_site_id, :phone]
  end
end
