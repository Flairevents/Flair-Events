class AddNotesToExpense < ActiveRecord::Migration[5.1]
  def change
    add_column :expenses, :notes, :text 
    change_column_null :expenses, :cost, true
  end
end
