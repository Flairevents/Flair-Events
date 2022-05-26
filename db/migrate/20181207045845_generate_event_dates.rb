class GenerateEventDates < ActiveRecord::Migration[5.2]
  def up
    cutoff_date = TaxWeek.all.sort_by(&:date_start).first.date_start
    Event.includes(:assignments).where("STATUS <> 'CANCELLED'").each do |event|
      dates_to_create = []
      if event.assignments.length > 0
        shift_ids = event.assignments.pluck(:shift_id).uniq
        dates_to_create = Shift.find(shift_ids).pluck(:date).uniq
      else
        (event.date_start..event.date_end).each do |date|
          dates_to_create << date
        end
      end  
      dates_to_create.select {|date| date >= cutoff_date}.uniq.each do |date|
        event_date = EventDate.new
        event_date.event_id = event.id
        event_date.date = date
        event_date.save!
      end
    end
  end
  def down
    EventDate.destroy_all
  end
end
