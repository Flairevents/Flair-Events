class RenameEtihadIdColumnOnProspects < ActiveRecord::Migration[5.2]
  def change
    rename_column :prospects, :etihad_id, :etihad_id_number
  end
end
