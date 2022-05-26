class CreatePayrollActivity < ActiveRecord::Migration[5.1]
  def change
    create_table :payroll_activities do |t|
      t.references :tax_week, index: true
      t.references :prospect, index: true
      t.string    :action, null: false
      t.timestamps
    end
  end
end
