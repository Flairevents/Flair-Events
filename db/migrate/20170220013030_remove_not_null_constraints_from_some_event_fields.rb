class RemoveNotNullConstraintsFromSomeEventFields < ActiveRecord::Migration
  def change
    change_column :events, :date_start, :date, null: true
    change_column :events, :date_end, :date, null: true
    change_column :events, :category_id, :integer, null: true
  end
end
