class RenameEnergyVibeColumnOnBookings < ActiveRecord::Migration[5.1]
  def change
    rename_column :bookings, :energy_vibe, :staff_qualities
  end
end
