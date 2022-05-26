class AddEtihadIdToProspect < ActiveRecord::Migration[5.1]
  def change
    add_column :prospects, :etihad_id, :integer
  end
end
