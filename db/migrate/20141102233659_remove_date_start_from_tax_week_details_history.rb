class RemoveDateStartFromTaxWeekDetailsHistory < ActiveRecord::Migration
  def up
    remove_column :tax_week_details_histories, :date_start
  end

  def down
    add_column :tax_week_details_histories, :date_start, :date
  end
end
