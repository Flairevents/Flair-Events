class ChangeColumnNamesWithForApplicantTab < ActiveRecord::Migration[5.2]
  def change
    rename_column :prospects, :e_mail, :email_status
    rename_column :prospects, :voice_message, :left_voice_message
    rename_column :prospects, :missed_interview, :missed_interview_date
    rename_column :prospects, :txt, :texted_date
    rename_column :prospects, :head_quarter, :headquarter
  end
end
