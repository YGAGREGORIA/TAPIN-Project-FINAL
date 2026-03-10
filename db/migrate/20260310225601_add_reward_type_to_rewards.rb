class AddRewardTypeToRewards < ActiveRecord::Migration[8.1]
  def change
    add_column :rewards, :reward_type, :integer, default: 0, null: false
  end
end
