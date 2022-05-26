class AddDateSentAndDateReceivedToBooking < ActiveRecord::Migration[5.1]
  def change
    add_column :bookings, :date_sent,     :date
    add_column :bookings, :date_received, :date
  end
end
