class AddVisitsRequiredToRewards < ActiveRecord::Migration[8.1]
  def change
    add_column :rewards, :visits_required, :integer, default: 10, null: false
  end
end
