class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.string :tag
      t.string :role
      t.string :sentiment
      t.string :content
      t.string :summary

      t.timestamps
    end
  end
end
