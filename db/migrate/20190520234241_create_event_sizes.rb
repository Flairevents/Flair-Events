class CreateEventSizes < ActiveRecord::Migration[5.2]
  def change
    create_table :event_sizes do |t|
      t.string :name, null: false, unique: true
      t.integer :order, null: false, unique: true
      t.timestamps null: false
    end
  end
end
