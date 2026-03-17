class ChangePhoneToStringOnUsers < ActiveRecord::Migration[8.1]
  def up
    change_column :users, :phone, :string
    change_column_null :visits, :class_config_id, true
  end

  def down
    change_column :users, :phone, :integer
    change_column_null :visits, :class_config_id, false
  end
end
