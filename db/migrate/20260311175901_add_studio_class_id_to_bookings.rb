class AddStudioClassIdToBookings < ActiveRecord::Migration[8.1]
  def change
    add_reference :bookings, :studio_class, null: true, foreign_key: true
  end
end
