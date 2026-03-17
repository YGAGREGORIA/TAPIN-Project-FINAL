class CreateMbClassDescriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :mb_class_descriptions do |t|
      t.string  :mb_class_description_id, null: false
      t.string  :name, null: false
      t.text    :description
      t.string  :category
      t.integer :duration_minutes
      t.string  :mb_site_id, null: false

      t.timestamps
    end

    add_index :mb_class_descriptions, [:mb_site_id, :mb_class_description_id],
              unique: true, name: "idx_mb_class_desc_on_site_and_desc_id"
  end
end
