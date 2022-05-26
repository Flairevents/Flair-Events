class AddInvoiceFrequencyFieldsToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :invoice_frequency_in_weeks, :integer, default: 1
    add_column :events, :invoice_frequency_start_tax_week_id, :integer
    Event.where(is_ongoing: true).all.each do |event|
      tax_week = TaxWeek.where('date_start <= ? AND ? <= date_end', event.date_start, event.date_start).first
      event.invoice_frequency_start_tax_week_id = tax_week.id
      event.save
    end
  end
end
