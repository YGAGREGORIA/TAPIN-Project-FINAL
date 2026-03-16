class CreateMbStaff < ActiveRecord::Migration[8.1]
  def change
    create_table :mb_staff do |t|
      t.string :mb_staff_id, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.text   :bio
      t.string :image_url
      t.string :mb_site_id, null: false

      t.timestamps
    end

    add_index :mb_staff, [:mb_site_id, :mb_staff_id], unique: true
  end
end
