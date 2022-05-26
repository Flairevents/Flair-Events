class ClearBookingAmendments < ActiveRecord::Migration
  def change
    Booking.update_all(amendments: nil)
  end
end
