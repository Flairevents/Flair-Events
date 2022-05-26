class AddTimestampsToPayWeekDetailsHistory < ActiveRecord::Migration[5.1]
  def up
    ##### Initially create timestamps with default of today
    ##### (otherwise existing entries would be invalid since
    ##### timestamps cannot be nil
    add_timestamps :pay_week_details_histories, default: DateTime.now

    ##### Since the PayWeekDetailsHistories stores the tax_week, we'll use
    ##### that to set the timestamp dates
    PayWeekDetailsHistory.all.each do |pwdh|
      tax_week = TaxWeek.find(pwdh.tax_week_id)
      pwdh.created_at = tax_week.date_end+1.day
      pwdh.updated_at = tax_week.date_end+1.day
      pwdh.save
    end

    ##### Restore expected default of nil for timestamps
    change_column_default :pay_week_details_histories, :created_at, nil
    change_column_default :pay_week_details_histories, :updated_at, nil
  end
  def down
    remove_column :pay_week_details_histories, :created_at
    remove_column :pay_week_details_histories, :updated_at
  end
end
