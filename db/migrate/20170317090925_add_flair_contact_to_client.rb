class AddFlairContactToClient < ActiveRecord::Migration
  def change
    add_column :clients, :flair_contact, :string
  end
end
