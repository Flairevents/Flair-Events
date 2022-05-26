class AddDefaultAssignment < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :default_assignment_id, :integer
  end
end
