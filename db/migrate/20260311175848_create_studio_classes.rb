class CreateStudioClasses < ActiveRecord::Migration[8.1]
  def change
    create_table :studio_classes do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :name
      t.string :teacher_name
      t.text :description
      t.string :class_type
      t.datetime :scheduled_at
      t.integer :duration_minutes, default: 60
      t.integer :capacity, default: 20
      t.integer :spots_taken, default: 0

      t.timestamps
    end
  end
end
