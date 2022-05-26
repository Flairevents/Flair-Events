class AddPublicNameToShift < ActiveRecord::Migration[5.1]
  def change
    add_column :jobs, :public_name, :string
  end
end
