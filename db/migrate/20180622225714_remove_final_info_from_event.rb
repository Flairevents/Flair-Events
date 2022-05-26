class RemoveFinalInfoFromEvent < ActiveRecord::Migration[5.1]
  def change
    remove_column :events, :final_info
  end
end
