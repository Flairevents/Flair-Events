class RemoveDateStartAndDateEndFromPayWeek < ActiveRecord::Migration[5.1]
  def change
    remove_column :pay_weeks, :date_start, :date
    remove_column :pay_weeks, :date_end, :date
  end
end
