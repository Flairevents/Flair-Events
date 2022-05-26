class RemoveNotesFromInvoices < ActiveRecord::Migration[5.1]
  def change
    remove_column :invoices, :notes
  end
end
