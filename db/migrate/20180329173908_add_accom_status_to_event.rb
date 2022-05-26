class AddAccomStatusToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :accom_status, :string, null: false, default: 'NONE'
  end
end
