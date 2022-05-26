class ChangeAssignmentEmailTypeOnGigTaxWeekFromConfirmToReserve < ActiveRecord::Migration[5.1]
  def up
    GigTaxWeek.where(assignment_email_type: 'Confirm').update_all(assignment_email_type: 'Reserve')
  end
  def down
    GigTaxWeek.where(assignment_email_type: 'Reserve').update_all(assignment_email_type: 'Confirm')
  end
end
