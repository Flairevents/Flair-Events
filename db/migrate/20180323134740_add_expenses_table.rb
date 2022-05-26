class AddExpensesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :expenses do |t|
      t.integer :event_id, null: false
      t.string  :name, null: false
      t.decimal :cost, precision: 8, scale: 2, null: false
      t.timestamps null: false
    end
  end
end
