class AddQualificationDbsToProspect < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :qualification_dbs, :boolean, null: false, default: false
  end
end
