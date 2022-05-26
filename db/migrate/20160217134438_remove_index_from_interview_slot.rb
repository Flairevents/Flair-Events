class RemoveIndexFromInterviewSlot < ActiveRecord::Migration
  def change
    remove_column :interview_slots, :index, :integer
  end
end
