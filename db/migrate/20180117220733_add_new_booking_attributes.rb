class AddNewBookingAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :bookings, :event_description, :text
    add_column :bookings, :selling_points, :text
    add_column :bookings, :energy_vibe, :text
  end
end
