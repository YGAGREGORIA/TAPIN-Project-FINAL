class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :studio, null: false, foreign_key: true
      t.string :notification_type
      t.string :title
      t.string :body
      t.string :path
      t.datetime :read_at
      t.datetime :sent_at

      t.timestamps
    end
  end
end
