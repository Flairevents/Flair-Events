class UpdateRegSheetReports < ActiveRecord::Migration[5.1]
  def up
    Report.where(name: 'reg_sheet_daily', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet_daily', print_name: 'Reg Sheet (Daily)', table: 'gigs',
                   fields: ['name', 'job_name', 'date', 'shift_start', 'shift_end', 'location', 'tag', 'notes'],
                   row_numbers: true,
                   worksheet_key: 'date')
  
    Report.where(name: 'reg_sheet', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet', print_name: 'Reg Sheet', table: 'gigs',
                   fields: ['name', 'job_name', 'date', 'shift_start', 'shift_end', 'location', 'tag', 'notes'],
                   row_numbers: true)
  end
  def down
    Report.where(name: 'reg_sheet_daily', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet_daily', print_name: 'Reg Sheet (Daily)', table: 'gigs',
                   fields: ['name', 'job_name', 'date', 'shift_times', 'location', 'tag', 'notes'],
                   row_numbers: true,
                   worksheet_key: 'date')
    Report.where(name: 'reg_sheet', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet', print_name: 'Reg Sheet', table: 'gigs',
                   fields: ['name', 'job_name', 'date', 'shift_times', 'location', 'tag', 'mobile_no', 'notes', 'email'],
                   row_numbers: true)    
  end
end
