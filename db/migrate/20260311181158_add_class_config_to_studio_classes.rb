class AddClassConfigToStudioClasses < ActiveRecord::Migration[8.1]
  def change
    add_reference :studio_classes, :class_config, null: true, foreign_key: true
  end
end
