class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :studio, null: false, foreign_key: true
      t.integer :mindbody_booking_id
      t.string :class_name
      t.datetime :class_time
      t.boolean :status
      t.datetime :booked_at

      t.timestamps
    end
  end
end
