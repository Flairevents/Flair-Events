class AddInterviewTypeIntoInterview < ActiveRecord::Migration[5.2]
  def change
    add_column :interviews, :interview_type, :string
  end
end
