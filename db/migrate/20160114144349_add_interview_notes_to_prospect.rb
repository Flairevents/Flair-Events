class AddInterviewNotesToProspect < ActiveRecord::Migration
  def up
    add_column :prospects, :interview_notes, :text
  end
  def down
    remove_column :prospects, :interview_notes
  end
end
