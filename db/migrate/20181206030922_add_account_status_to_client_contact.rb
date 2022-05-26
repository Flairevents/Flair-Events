class AddAccountStatusToClientContact < ActiveRecord::Migration[5.2]
  def change
    add_column :client_contacts, :account_status, :string, null: false, default: 'NEW'
  end
end
