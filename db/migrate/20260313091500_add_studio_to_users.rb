class AddStudioToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :studio, :string
  end
end
