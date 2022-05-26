class AddIsColumnsToInterviewBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :interview_blocks, :is_morning, :boolean
    add_column :interview_blocks, :morning_applicants, :integer, default: 0
    add_column :interview_blocks, :is_afternoon, :boolean
    add_column :interview_blocks, :afternoon_applicants, :integer, default: 0
    add_column :interview_blocks, :is_evening, :boolean
    add_column :interview_blocks, :evening_applicants, :integer, default: 0
  end
end
