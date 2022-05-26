class AddSeniorManagerToOfficers < ActiveRecord::Migration[5.2]
  def change
    add_column :officers, :senior_manager, :boolean
  end
end
