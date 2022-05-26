class AddBookingFieldsToEvent < ActiveRecord::Migration
  def change
    add_column :events, :booking_dates, :string
    add_column :events, :booking_timings, :string
    add_column :events, :booking_crew_required, :string
    add_column :events, :booking_uniform, :string
    add_column :events, :booking_food, :string
    add_column :events, :booking_breaks, :string
    add_column :events, :booking_rates, :string
    add_column :events, :booking_wages, :string
    add_column :events, :booking_terms, :string
    add_column :events, :booking_invoicing, :string
    add_column :events, :booking_timesheets, :string
    add_column :events, :booking_any_other_information, :string
  end
end
