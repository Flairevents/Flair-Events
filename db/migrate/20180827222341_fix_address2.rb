class FixAddress2 < ActiveRecord::Migration[5.2]
  def up
    PayWeekDetailsHistory.where(address2: nil).update_all(address2: '')
  end
end
