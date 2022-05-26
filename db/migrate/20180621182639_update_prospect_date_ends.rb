class UpdateProspectDateEnds < ActiveRecord::Migration[5.1]
  def change
    PayrollActivity.joins(:tax_week).order('tax_weeks.date_start asc').group_by(&:prospect).each do |prospect, payroll_activities|
      last_payroll_activity = payroll_activities.last
      if last_payroll_activity.action == 'ADDED' 
        prospect.date_end = nil
      else
        prospect.date_end = last_payroll_activity.tax_week.date_end
      end
      prospect.save!
    end
  end
end
