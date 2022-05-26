class UpdateEventNotesDefaultAndNotNull < ActiveRecord::Migration[5.2]
  def change
    Event.where(notes: nil).update_all(notes: '')
    change_column :events, :notes, :text, default: '', null: false
  end
end
