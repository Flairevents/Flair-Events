class CreateTaxWeek < ActiveRecord::Migration[4.2]
  def change
    create_table :tax_years do |t|
      t.date       :date_start, unique: true
      t.date       :date_end,   unique: true
      t.timestamps null: false
    end
    create_table :tax_weeks do |t|
      t.integer    :tax_year_id
      t.integer    :week
      t.date       :date_start,    unique: true
      t.date       :date_end,      unique: true
      t.timestamps null: false
    end
    add_index :tax_weeks, [:tax_year_id, :week], unique: true
  end
end
