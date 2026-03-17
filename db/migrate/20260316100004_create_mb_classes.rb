class CreateMbClasses < ActiveRecord::Migration[8.1]
  def change
    create_table :mb_classes do |t|
      t.string   :mb_class_id, null: false
      t.references :mb_class_description, null: false, foreign_key: true
      t.references :mb_staff, null: false, foreign_key: { to_table: :mb_staff }
      t.datetime :start_datetime, null: false
      t.datetime :end_datetime, null: false
      t.integer  :max_capacity, default: 20
      t.integer  :total_booked, default: 0
      t.boolean  :is_canceled, default: false
      t.string   :location
      t.string   :mb_site_id, null: false

      t.timestamps
    end

    add_index :mb_classes, [:mb_site_id, :mb_class_id], unique: true
  end
end
