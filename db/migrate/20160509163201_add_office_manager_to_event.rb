class AddOfficeManagerToEvent < ActiveRecord::Migration
  def change
    rename_column :events, :manager, :site_manager
    add_column :events, :office_manager, :string
  end
end
