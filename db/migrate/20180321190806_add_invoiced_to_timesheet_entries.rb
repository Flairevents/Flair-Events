class AddInvoicedToTimesheetEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :timesheet_entries, :invoiced, :boolean, null: false, default: false
  end
end
