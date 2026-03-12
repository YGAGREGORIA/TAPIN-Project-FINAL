class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint
      t.string :p256dh_key
      t.string :auth_key

      t.timestamps
    end
  end
end
