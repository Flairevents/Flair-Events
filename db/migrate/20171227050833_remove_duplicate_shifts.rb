class RemoveDuplicateShifts < ActiveRecord::Migration[5.1]
  def up
    all_shifts = {}
    Event.all.each do |event|
      all_shifts[event.id] = {}
      event.shifts.each do |shift|
        if all_shifts[event.id][shift.date] && all_shifts[event.id][shift.date][shift.time_start] && all_shifts[event.id][shift.date][shift.time_start][shift.time_end]
          shift.destroy
        else
          all_shifts[event.id][shift.date] ||= {}
          all_shifts[event.id][shift.date][shift.time_start] ||= {}
          all_shifts[event.id][shift.date][shift.time_start][shift.time_end] = true
        end
      end  
    end
  end
end
