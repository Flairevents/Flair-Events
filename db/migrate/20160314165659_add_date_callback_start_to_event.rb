class AddDateCallbackStartToEvent < ActiveRecord::Migration
  def change
    add_column :events, :date_callback_start, :date
  end
end
