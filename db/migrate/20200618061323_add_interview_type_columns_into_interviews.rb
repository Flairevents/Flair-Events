class AddInterviewTypeColumnsIntoInterviews < ActiveRecord::Migration[5.2]
  def change
    add_column :interviews, :telephone_call_interview, :boolean
    add_column :interviews, :video_call_interview, :boolean
  end
end
