class AddSeniorManagerIdToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :senior_manager_id, :integer
  end
end
