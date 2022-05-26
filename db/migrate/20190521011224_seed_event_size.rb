class SeedEventSize < ActiveRecord::Migration[5.2]
  def up
    EventSize.create! name: 'Small 1-10', order: 1
    EventSize.create! name: '1 Day Simple', order: 2
    EventSize.create! name: 'Medium+', order: 3
    EventSize.create! name: 'Large', order: 4
    EventSize.create! name: 'Complex', order: 5
  end
  def down
    EventSize.destroy_all
  end
end
