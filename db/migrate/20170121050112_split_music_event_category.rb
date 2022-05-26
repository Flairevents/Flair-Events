class SplitMusicEventCategory < ActiveRecord::Migration
  def up
    ec_festival = EventCategory.where(name: 'Music').first
    ec_festival.name = 'Festival'
    ec_festival.save
    ec_concert = EventCategory.new
    ec_concert.name = 'Concert'
    ec_concert.save
    Event.where(category_id: ec_festival.id, is_concert: true).each do |e|
      puts("Switching #{e.name} to concert")
      e.category_id = ec_concert.id
      e.save
    end
  end
end
