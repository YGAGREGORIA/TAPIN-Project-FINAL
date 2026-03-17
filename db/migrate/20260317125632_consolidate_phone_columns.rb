class ConsolidatePhoneColumns < ActiveRecord::Migration[8.1]
  def up
    if column_exists?(:users, :phone_number)
      # Copy phone_number data into phone where phone is blank
      execute <<-SQL
        UPDATE users
        SET phone = phone_number
        WHERE (phone IS NULL OR phone = '')
          AND phone_number IS NOT NULL
          AND phone_number != ''
      SQL

      remove_index :users, :phone_number, if_exists: true
      remove_column :users, :phone_number
    end

    # Add unique index on phone (allow nulls for admin users without phone)
    unless index_exists?(:users, :phone, where: "phone IS NOT NULL AND phone != ''")
      add_index :users, :phone, unique: true, where: "phone IS NOT NULL AND phone != ''"
    end
  end

  def down
    unless column_exists?(:users, :phone_number)
      add_column :users, :phone_number, :string
      add_index :users, :phone_number, unique: true
    end

    remove_index :users, :phone, if_exists: true
  end
end
