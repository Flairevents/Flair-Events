class AddOtherInfoToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :other_info, :text
  end
end
