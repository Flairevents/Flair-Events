class AddManagerLevelToProspect < ActiveRecord::Migration
  def change
    add_column :prospects, :manager_level, :string
  end
end
