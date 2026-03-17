class AddSocialLinksToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :instagram, :string
    add_column :users, :facebook, :string
    add_column :users, :linkedin, :string
  end
end
