class RemoveUnusedLoggedInColumn < ActiveRecord::Migration[5.1]
  def change
  	remove_column :officers, :logged_in
  end
end
