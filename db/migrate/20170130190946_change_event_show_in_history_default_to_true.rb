class ChangeEventShowInHistoryDefaultToTrue < ActiveRecord::Migration
  def change
    change_column_default :events, :show_in_history, true
  end
end
