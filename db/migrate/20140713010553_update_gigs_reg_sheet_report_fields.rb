class UpdateGigsRegSheetReportFields < ActiveRecord::Migration
  def up
    Report.where(name: 'reg_sheet', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet', print_name: 'Reg Sheet', table: 'gigs',
                   fields: ['name', 'job_name', 'shift_times', 'location', 'mobile_no', 'notes', 'email'],
                   row_numbers: true)
  end

  def down
    Report.where(name: 'reg_sheet', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet', print_name: 'Reg Sheet', table: 'gigs',
                   fields: ['name', 'has_tax', 'has_id', 'has_ni', 'location', 'job_name', 'transport', 'notes', 'avg_rating'],
                   row_numbers: true)
  end
end
