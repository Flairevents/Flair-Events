class AddConfirmedStaffCountToAssignment < ActiveRecord::Migration[5.1]
  def up
    add_column :assignments, :confirmed_staff_count, :integer, null: false, default: 0 
    Assignment.all.each {|assignment| assignment.update_counts }
  end
  def down
    remove_column :assignments, :confirmed_staff_count
  end  
end
