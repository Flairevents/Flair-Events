class RemoveUnneededEventTransportationFields < ActiveRecord::Migration[5.1]
  def change
    remove_column :events, :trans_required,         :string
    remove_column :events, :trans_types_used,       :string
    remove_column :events, :trans_bookings_made,    :boolean, null: false, default: false
    remove_column :events, :trans_booking_refs,     :string
    remove_column :events, :trans_tickets_received, :boolean, null: false, default: false
    remove_column :events, :trans_cost,             :string
    rename_column :events, :trans_notes, :expense_notes
  end
end
