class CreateBroadcasts < ActiveRecord::Migration[8.1]
  def change
    create_table :broadcasts do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :subject
      t.text :body
      t.string :audience_filter
      t.string :channel
      t.datetime :scheduled_at
      t.datetime :sent_at
      t.integer :total_sent
      t.integer :total_delivered
      t.integer :total_failed

      t.timestamps
    end
  end
end
