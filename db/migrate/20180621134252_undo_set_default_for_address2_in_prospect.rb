class UndoSetDefaultForAddress2InProspect < ActiveRecord::Migration[5.1]
  def change
    change_column_null :prospects, :address2, true
    execute 'alter table prospects alter address2 drop default'
    Prospect.where(address2: nil).update_all(address2: '')
    PayWeekDetailsHistory.where(address2: nil).update_all(address2: '')
  end
end
