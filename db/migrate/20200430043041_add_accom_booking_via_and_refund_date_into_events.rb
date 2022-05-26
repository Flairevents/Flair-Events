class AddAccomBookingViaAndRefundDateIntoEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :accom_booking_via, :string
    add_column :events, :accom_refund_date, :date
  end
end
