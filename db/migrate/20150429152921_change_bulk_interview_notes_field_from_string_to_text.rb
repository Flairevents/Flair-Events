class ChangeBulkInterviewNotesFieldFromStringToText < ActiveRecord::Migration
  def up
    change_column :bulk_interviews, :note_for_applicant, :text, :limit => nil
  end

  def down
    change_column :bulk_interviews, :note_for_applicant, :string
  end
end
