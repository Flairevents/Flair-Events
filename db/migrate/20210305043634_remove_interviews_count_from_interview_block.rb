class RemoveInterviewsCountFromInterviewBlock < ActiveRecord::Migration[5.2]
  def change
    remove_column :interview_blocks, :interviews_count, :integer
  end
end
