class CreateNotificationTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_templates do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :event_type
      t.string :title_template
      t.string :body_template
      t.boolean :enabled

      t.timestamps
    end
  end
end
