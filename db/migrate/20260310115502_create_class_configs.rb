class CreateClassConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :class_configs do |t|
      t.references :studio, null: false, foreign_key: true
      t.integer :mindbody_class_id
      t.string :class_name
      t.integer :point_value
      t.boolean :is_premium

      t.timestamps
    end
  end
end
