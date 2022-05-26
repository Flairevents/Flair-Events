class CreateTotalEventsTextBlock < ActiveRecord::Migration[5.1]
  def up
    TextBlock.new(key: 'total-events', type: 'page', status: 'PUBLISHED', contents: '0').save!
  end
  def down
    TextBlock.where(key: 'total-events').destroy_all
  end
end
