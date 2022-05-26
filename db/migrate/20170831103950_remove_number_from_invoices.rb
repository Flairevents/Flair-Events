class RemoveNumberFromInvoices < ActiveRecord::Migration[5.1]
  def change
    remove_column :invoices, :number
  end
end
