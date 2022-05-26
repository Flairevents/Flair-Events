class AddNotesToInvoices < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :notes, :text
  end
end
