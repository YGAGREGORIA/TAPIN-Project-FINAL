class CreateMindbodyLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :mindbody_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :mindbody_client_id
      t.string :status, default: "pending"
      t.json :match_data
      t.datetime :linked_at

      t.timestamps
    end
  end
end
