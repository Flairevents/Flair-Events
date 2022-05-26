class AddPayUnder18ToShift < ActiveRecord::Migration
  def up
    add_column :shifts, :pay_under_18, :decimal
    Shift.all.each do |s|
      s.pay_under_18 = 5.0 #We don't want to default to 5.0, but we do want to set it for all existing shifts
      s.save 
    end
  end
  def down
    remove_column :shifts, :pay_under_18
  end
end
