class AddRequiresBookingToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :requires_booking, :boolean, null: false, default: true
  end
end
