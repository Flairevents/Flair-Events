class AddShowInOngoingToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :show_in_ongoing, :boolean, null: false, default: false
    Event.reset_column_information
    Event.where(is_ongoing: true).update_all(show_in_ongoing: true)
  end
end
