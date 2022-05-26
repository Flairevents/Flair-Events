class RemoveOldClientFields < ActiveRecord::Migration
  def change
    remove_column :clients, :primary_contact_name, :string
    remove_column :clients, :primary_contact_email, :string
    remove_column :clients, :primary_contact_mobile_no, :string
  end
end
