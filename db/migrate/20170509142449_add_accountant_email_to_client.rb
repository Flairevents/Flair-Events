class AddAccountantEmailToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :clients, :accountant_email, :string
  end
end
