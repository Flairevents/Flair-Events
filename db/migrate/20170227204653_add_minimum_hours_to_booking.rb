class AddMinimumHoursToBooking < ActiveRecord::Migration
  def change
    add_column :bookings, :minimum_hours, :string
  end
end
