class RenameInterviewNotesToPerformanceNotesOnProspect < ActiveRecord::Migration[5.1]
  def change
    rename_column :prospects, :interview_notes, :performance_notes
  end
end
