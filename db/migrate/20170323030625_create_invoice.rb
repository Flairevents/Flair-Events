class CreateInvoice < ActiveRecord::Migration[4.2]
  def change
    create_table :invoices do |t|
      t.integer :event_client_id
      t.string  :number
      t.string  :who
      t.string  :status
      t.date    :date
      t.integer :tax_year
      t.integer :tax_week
      t.timestamps null: false
    end
  end
end
