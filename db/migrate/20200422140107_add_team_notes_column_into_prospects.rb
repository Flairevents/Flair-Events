class AddTeamNotesColumnIntoProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :team_notes, :text
  end
end
