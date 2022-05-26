class RenameDateCallbackToDateCallbackDueOnEvent < ActiveRecord::Migration
  def change
    rename_column :events, :date_callback, :date_callback_due
  end
end
