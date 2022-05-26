class AddInterviewsNewCountToInterviewBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :interview_blocks, :morning_interviews, :integer, default: 0
    add_column :interview_blocks, :afternoon_interviews, :integer, default: 0
    add_column :interview_blocks, :evening_interviews, :integer, default: 0
  end
end
