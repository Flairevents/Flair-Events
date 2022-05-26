class FixMissingDateOpenedOnEvents < ActiveRecord::Migration[4.2]
  def up
    Event.where(status: 'OPEN').where('date_opened IS NULL').all.each do |e|
      e.date_opened = e.updated_at
      e.save
    end
  end
end
