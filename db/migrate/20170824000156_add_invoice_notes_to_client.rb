class AddInvoiceNotesToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :clients, :invoice_notes, :text
  end
end
