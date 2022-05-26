class SetDefaultForAddress2InProspect < ActiveRecord::Migration[5.1]
  def change
    Prospect.where(address2: nil).update_all(address2: '')
    PayWeekDetailsHistory.where(address2: nil).update_all(address2: '')
    change_column :prospects, :address2, :string, null: false, default: ''
  end
end
