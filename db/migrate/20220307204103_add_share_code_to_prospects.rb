class AddShareCodeToProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :share_code, :string
  end
end
