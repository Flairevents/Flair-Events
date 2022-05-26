class CreateActionTakens < ActiveRecord::Migration[5.2]
  def change
    create_table :action_takens do |t|
      t.text :action
      t.text :reason
      t.references :event, foreign_key: true
      t.references :prospect, foreign_key: true

      t.timestamps
    end
  end
end
