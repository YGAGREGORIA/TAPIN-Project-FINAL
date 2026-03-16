class AddConfirmableAndLockableToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime

    add_index :users, :confirmation_token, unique: true
    add_index :users, :unlock_token, unique: true

    execute <<~SQL.squish
      UPDATE users
      SET confirmed_at = COALESCE(confirmed_at, CURRENT_TIMESTAMP),
          confirmation_sent_at = COALESCE(confirmation_sent_at, CURRENT_TIMESTAMP)
      WHERE email IS NOT NULL AND email <> ''
    SQL
  end

  def down
    remove_index :users, :unlock_token
    remove_index :users, :confirmation_token

    remove_column :users, :locked_at
    remove_column :users, :unlock_token
    remove_column :users, :failed_attempts

    remove_column :users, :unconfirmed_email
    remove_column :users, :confirmation_sent_at
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_token
  end
end
