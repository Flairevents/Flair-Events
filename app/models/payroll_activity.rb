class PayrollActivity < ApplicationRecord
  belongs_to :tax_week
  belongs_to :prospect

  validates_inclusion_of :action, in: %w(ADDED REMOVED), allow_nil: false

  after_commit do
    tax_week_ids = TaxWeek.where(tax_year_id: self.tax_week.tax_year_id).pluck(:id)
    last_payroll_activity = self.prospect.payroll_activities.joins(:tax_week).where(tax_week_id: tax_week_ids).order('tax_weeks.date_start asc').last
    case last_payroll_activity.action
    when 'ADDED'
      self.prospect.date_end = nil
    when 'REMOVED'
      self.prospect.date_end = last_payroll_activity.tax_week.date_end
    end
    self.prospect.save
  end
end