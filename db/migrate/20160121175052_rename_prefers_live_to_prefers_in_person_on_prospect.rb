class RenamePrefersLiveToPrefersInPersonOnProspect < ActiveRecord::Migration
  def change
    rename_column :prospects, :prefers_live, :prefers_in_person
  end
end
