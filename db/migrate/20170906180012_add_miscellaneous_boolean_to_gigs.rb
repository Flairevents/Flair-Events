class AddMiscellaneousBooleanToGigs < ActiveRecord::Migration[5.1]
  def change
    add_column :gigs, :miscellaneous_boolean, :boolean, null: false, default: false
  end
end
