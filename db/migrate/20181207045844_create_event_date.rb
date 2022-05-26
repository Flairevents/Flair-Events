class CreateEventDate < ActiveRecord::Migration[5.2]
  def change
    create_table :event_dates do |t|
      t.references :event, foreign_key: true, null: false
      t.references :tax_week, foreign_key: true, null: false
      t.date :date, null: false
      t.timestamps
    end
  end
end
