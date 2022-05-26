class UpdateNewEventProperties < ActiveRecord::Migration[5.2]
  def change
    Event.all.each do |event|
      event.update_next_active_date
      event.save!
    end
    Event.connection.schema_cache.clear!
    Event.reset_column_information
    change_column_null :events, :next_active_date, false
    Event.all.each do |event|
      event.region_id = event.region_id_from_post_code
      event.save
    end
  end
end
