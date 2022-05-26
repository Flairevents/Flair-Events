class ChangeDefaultShowInPlannerInEvents < ActiveRecord::Migration[5.2]
  def change
    change_column_default :events, :show_in_planner, true
  end
end
