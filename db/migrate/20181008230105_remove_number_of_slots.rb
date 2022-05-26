class RemoveNumberOfSlots < ActiveRecord::Migration[5.2]
  def change
    # This column on interview_blocks is not used for anything
    remove_column :interview_blocks, :number_of_slots
  end
end
