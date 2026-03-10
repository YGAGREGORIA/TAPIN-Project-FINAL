class CreateRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :rewards do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :name
      t.integer :points_cost
      t.string :image_url
      t.text :description
      t.boolean :active

      t.timestamps
    end
  end
end
