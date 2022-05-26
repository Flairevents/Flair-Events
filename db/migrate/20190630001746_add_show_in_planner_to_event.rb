class AddShowInPlannerToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :show_in_planner, :boolean, default: false, null: false
  end
end
