class AddTypeToPayWeeks < ActiveRecord::Migration[5.1]
  def change
    add_column :pay_weeks, :type, :string
    PayWeek.update_all(type: 'MANUAL')
    change_column_null :pay_weeks, :type, false
  end
end
