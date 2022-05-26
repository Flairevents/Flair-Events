class AddLeaderClientContactToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :leader_client_contact_id, :integer
  end
end
