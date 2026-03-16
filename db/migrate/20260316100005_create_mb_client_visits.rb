class CreateMbClientVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :mb_client_visits do |t|
      t.string   :mb_visit_id, null: false
      t.references :mb_client, null: false, foreign_key: true
      t.references :mb_class, null: false, foreign_key: { to_table: :mb_classes }
      t.string   :visit_type, default: "class"
      t.boolean  :signed_in, default: true
      t.datetime :arrival_datetime
      t.string   :mb_site_id, null: false

      t.timestamps
    end

    add_index :mb_client_visits, [:mb_site_id, :mb_visit_id], unique: true
    add_index :mb_client_visits, [:mb_client_id, :mb_class_id]
  end
end
