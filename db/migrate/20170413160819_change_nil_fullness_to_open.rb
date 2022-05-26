class ChangeNilFullnessToOpen < ActiveRecord::Migration[4.2]
  def change
    change_column_default(:events, :fullness, 'OPEN')
    Event.all.each do |e|
      unless e.fullness
        e.fullness = 'OPEN'
        e.save
      end
    end
  end
end
