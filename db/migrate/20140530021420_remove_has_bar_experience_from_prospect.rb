class RemoveHasBarExperienceFromProspect < ActiveRecord::Migration
  def up
    remove_column :prospects, :has_bar_license
  end

  def down
    add_column :prospects, :has_bar_license, :boolean
  end
end
