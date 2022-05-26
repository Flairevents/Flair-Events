class AddNewEventTaskTemplate < ActiveRecord::Migration[5.2]
  def change
    EventTaskTemplate.create(task: 'Re-asses Next Team')
  end
end
