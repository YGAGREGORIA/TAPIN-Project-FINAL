class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.integer :phone
      t.string :first_name
      t.string :last_name
      t.integer :total_points
      t.integer :available_points
      t.integer :total_visits
      t.string :referred_by
      t.datetime :last_visit_at

      t.timestamps
    end
  end
end
