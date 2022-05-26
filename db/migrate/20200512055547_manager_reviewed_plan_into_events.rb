class ManagerReviewedPlanIntoEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :reviewed_by_manager, :integer
  end
end
