class RemoveCallbackStartFromEvent < ActiveRecord::Migration
  def change
    remove_column :events, :date_callback_start, :date
  end
end
