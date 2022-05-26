class AddOriginalIdSightedToProspects < ActiveRecord::Migration
  def up
    add_column :prospects, :original_id_sighted, :date
  end
  def down
    remove_column :prospects, :original_id_sighted
  end
end
