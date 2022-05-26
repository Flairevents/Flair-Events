class RemoveBookingFieldsFromEvent < ActiveRecord::Migration
  def change
    remove_column :events, :booking_dates, :string
    remove_column :events, :booking_timings, :string
    remove_column :events, :booking_crew_required, :string
    remove_column :events, :booking_uniform, :string
    remove_column :events, :booking_food, :string
    remove_column :events, :booking_breaks, :string
    remove_column :events, :booking_rates, :string
    remove_column :events, :booking_wages, :string
    remove_column :events, :booking_terms, :string
    remove_column :events, :booking_invoicing, :string
    remove_column :events, :booking_timesheets, :string
    remove_column :events, :booking_any_other_information, :string
  end
end
