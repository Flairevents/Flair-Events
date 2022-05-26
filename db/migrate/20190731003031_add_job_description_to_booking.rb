class AddJobDescriptionToBooking < ActiveRecord::Migration[5.2]
  def change
    add_column :bookings, :job_description, :text
  end
end
