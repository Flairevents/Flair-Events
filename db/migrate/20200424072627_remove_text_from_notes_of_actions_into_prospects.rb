class RemoveTextFromNotesOfActionsIntoProspects < ActiveRecord::Migration[5.2]
  def change
    Prospect.where("notes LIKE ?", "%REMOVED from%").update_all(notes: '')
    Prospect.where("notes LIKE ?", "%DECLINED for%").update_all(notes: '')
  end
end
