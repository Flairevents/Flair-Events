class AddEmailsToClient < ActiveRecord::Migration
  def change
    add_column :clients, :email, :string
    add_column :clients, :primary_contact_email, :string
  end
end
