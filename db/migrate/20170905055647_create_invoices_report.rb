class CreateInvoicesReport < ActiveRecord::Migration[5.1]
  def up
    Report.create!(name: 'invoices', print_name: 'Invoices', table: 'invoices', row_numbers: true,
                   fields: ['client_name', 'event_name', 'event_dates', 'status', 'notes', 'tax_week'])
  end
  def down
    Report.where(name: 'invoices', table: 'invoices').destroy_all
  end
end
