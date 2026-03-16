class CreateMindbodyClients < ActiveRecord::Migration[8.1]
  def change
    create_table :mindbody_clients do |t|
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :email
      t.string :mindbody_client_id
      t.references :studio, null: false, foreign_key: true

      t.timestamps
    end

    add_index :mindbody_clients, [ :studio_id, :mindbody_client_id ], unique: true
    add_index :mindbody_clients, [ :studio_id, :phone ]
  end
end
