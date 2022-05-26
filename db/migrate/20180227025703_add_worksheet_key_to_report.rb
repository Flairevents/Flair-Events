class AddWorksheetKeyToReport < ActiveRecord::Migration[5.1]
  def change
    add_column :reports, :worksheet_key, :string, default: nil
  end
end
