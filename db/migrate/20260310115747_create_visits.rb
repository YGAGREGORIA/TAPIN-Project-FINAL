class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :studio, null: false, foreign_key: true
      t.references :class_config, null: false, foreign_key: true
      t.integer :points_earned
      t.datetime :visited_at

      t.timestamps
    end
  end
end
