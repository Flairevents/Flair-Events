class AddKidDatetimeToProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :kid_datetime, :datetime, default: nil
  end
end
