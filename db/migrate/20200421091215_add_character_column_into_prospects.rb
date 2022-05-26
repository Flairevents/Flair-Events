class AddCharacterColumnIntoProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :prospect_character, :string
  end
end
