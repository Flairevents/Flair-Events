class AddPublicDateStartAndEndToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :public_date_start, :date
    add_column :events, :public_date_end, :date

    Event.all.each do |event|
      event.public_date_start = event.date_start
      event.public_date_end = event.date_end
      event.save!
    end

    change_column_null :events, :public_date_start, false
    change_column_null :events, :public_date_end, false
  end
end
