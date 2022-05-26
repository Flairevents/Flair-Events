class AddTaxWeekIdToShift < ActiveRecord::Migration[5.1]
  def up
    add_reference :shifts, :tax_week

    Shift.all.each do |shift|
      tax_week = TaxWeek.where('date_start <= ? AND ? <= date_end', shift.date, shift.date).first
      if tax_week
        shift.tax_week_id = tax_week.id
        shift.save
      end
    end
  end
  def down
    remove_reference :shifts, :tax_week
  end 
end
