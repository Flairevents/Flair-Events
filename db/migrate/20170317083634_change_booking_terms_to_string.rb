class ChangeBookingTermsToString < ActiveRecord::Migration
  def change
    change_column :bookings, :terms, :string
  end
end
