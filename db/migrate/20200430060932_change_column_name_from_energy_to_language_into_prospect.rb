class ChangeColumnNameFromEnergyToLanguageIntoProspect < ActiveRecord::Migration[5.2]
  def change
    rename_column :prospects, :energy, :language
  end
end
