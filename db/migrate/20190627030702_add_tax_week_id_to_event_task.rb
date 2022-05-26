class AddTaxWeekIdToEventTask < ActiveRecord::Migration[5.2]
  def change
    add_reference :event_tasks, :tax_week, index: false
  end
end
