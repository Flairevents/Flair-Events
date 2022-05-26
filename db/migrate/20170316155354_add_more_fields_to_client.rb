class AddMoreFieldsToClient < ActiveRecord::Migration
  def change
    add_column :bookings, :office_notes, :text
    add_column :bookings, :amendments, :text
    add_column :bookings, :transport, :string
    add_column :bookings, :meeting_location, :string
  end
end
