class RemoveTimeTypeFromInterviewBlock < ActiveRecord::Migration[5.2]
  def change
    remove_column :interview_blocks, :time_type, :string
    remove_column :interview_blocks, :number_of_applicants, :integer
  end
end
