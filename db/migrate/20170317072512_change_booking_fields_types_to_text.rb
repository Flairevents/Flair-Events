class ChangeBookingFieldsTypesToText < ActiveRecord::Migration
  def change
    change_column :bookings, :dates,                 :text
    change_column :bookings, :timings,               :text
    change_column :bookings, :crew_required,         :text
    change_column :bookings, :uniform,               :text
    change_column :bookings, :food,                  :text
    change_column :bookings, :breaks,                :text
    change_column :bookings, :rates,                 :text
    change_column :bookings, :wages,                 :text
    change_column :bookings, :terms,                 :text
    change_column :bookings, :invoicing,             :text
    change_column :bookings, :timesheets,            :text
    change_column :bookings, :any_other_information, :text
    change_column :bookings, :transport,             :text
    change_column :bookings, :meeting_location,      :text

  end
end
