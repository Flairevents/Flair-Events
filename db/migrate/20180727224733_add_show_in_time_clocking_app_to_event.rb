class AddShowInTimeClockingAppToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :show_in_time_clocking_app, :boolean, null: false, default: false
  end
end
