class AddEventSizeToEvent < ActiveRecord::Migration[5.2]
  def change
    add_reference :events, :size, index: false, foreign_key: { to_table: :event_sizes }
  end
end
