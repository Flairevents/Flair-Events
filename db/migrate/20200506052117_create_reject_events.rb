class CreateRejectEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :reject_events do |t|
      t.boolean :has_seen, null: false, default: false
      t.references :event, foreign_key: true
      t.references :prospect, foreign_key: true

      t.timestamps
    end
  end
end
