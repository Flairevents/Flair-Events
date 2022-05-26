class UpdateShiftNameAndEndTime < ActiveRecord::Migration[5.1]
  def change
    remove_column :shifts, :name
    add_column :shifts, :name, :string 
    Event.all.each do |event|
      shifts = Shift.where(event_id: event.id).all
      if shifts.length > 1
        shifts.each_with_index do |shift, i|
          shift.name = ('A'.codepoints.first+i).chr
          shift.save!
        end
      end
      if shifts.length == 1
        shifts.first.name = '*'
        shifts.first.save!
      end
    end
    add_index :shifts, [:event_id, :name], unique: true
    Shift.all.each do |shift|
      if shift.time_start == shift.time_end
        shift.time_end = shift.time_start + 1.hour
        shift.save!
      end  
    end  
  end
end
