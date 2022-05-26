class CreateBooking < ActiveRecord::Migration
  def change
    create_table :bookings do |t|
      t.integer :event_client_id
      t.string :dates
      t.string :timings
      t.string :crew_required
      t.string :uniform
      t.string :food
      t.string :breaks
      t.string :rates
      t.string :wages
      t.string :terms
      t.string :invoicing
      t.string :timesheets
      t.string :any_other_information
      t.timestamps null: false
    end
  end
end
