class RemoveRememberTokenFromAccount < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :remember_token, :string
  end
end
