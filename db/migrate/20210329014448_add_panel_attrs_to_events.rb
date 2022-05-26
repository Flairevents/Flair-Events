class AddPanelAttrsToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :request_message, :text
    add_column :events, :spares_message, :text
    add_column :events, :applicants_message, :text
    add_column :events, :action_message, :text
  end
end
