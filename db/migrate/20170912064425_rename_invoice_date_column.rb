class RenameInvoiceDateColumn < ActiveRecord::Migration[5.1]
  def change
    rename_column :invoices, :date, :date_emailed
  end
end
