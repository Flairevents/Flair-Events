class AddPay25AndOverToShift < ActiveRecord::Migration
  def up
    add_column :shifts, :pay_25_and_over, :decimal
    Shift.all.each do |s|
      s.pay_25_and_over = s.pay_over_21 #Set for existing shifts
      s.save 
    end
  end
  def down
    remove_column :shifts, :pay_25_and_over
  end
end
