class RemoveUnnecessaryTextFromNotesIntoEvents < ActiveRecord::Migration[5.2]
  def change
    Event.where("notes LIKE ?", "%Other Office Manager%").update_all(notes: '')
  end
end
