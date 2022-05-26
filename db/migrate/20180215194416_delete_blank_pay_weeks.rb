class DeleteBlankPayWeeks < ActiveRecord::Migration[5.1]
  def change
    PayWeek.where(monday: 0, tuesday: 0, wednesday: 0, thursday: 0, friday: 0, saturday: 0, sunday: 0, allowance: 0, deduction: 0, status: 'SUBMITTED').destroy_all
  end
end
