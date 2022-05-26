class RemoveShiftName < ActiveRecord::Migration[5.1]
  def change
    remove_column :shifts, :name, :string
  end
end
