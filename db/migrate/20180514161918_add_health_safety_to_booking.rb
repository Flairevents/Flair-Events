class AddHealthSafetyToBooking < ActiveRecord::Migration[5.1]
  def change
    add_column :bookings, :health_safety, :text
  end
end
