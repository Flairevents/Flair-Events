class RemoveTaxCodeFromPayWeekDetailsHistory < ActiveRecord::Migration[5.2]
  def change
    remove_column :pay_week_details_histories, :tax_code, :string
  end
end
