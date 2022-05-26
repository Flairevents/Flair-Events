class AddPaidBreaksToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :paid_breaks, :boolean, null: false, default: false
  end
end
