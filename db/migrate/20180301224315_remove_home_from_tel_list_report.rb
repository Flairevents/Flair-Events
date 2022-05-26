class RemoveHomeFromTelListReport < ActiveRecord::Migration[5.1]
  def up 
    Report.where(name: 'gr_tel_no').destroy_all
    Report.create!(name: 'gr_tel_no', print_name: 'Applied - Tel List', table: 'gig_requests',
                   fields: ['name', 'mobile_no', 'emergency_no'],
                   row_numbers: true)
    Report.where(name: 'tel_no').destroy_all
    Report.create!(name: 'tel_no',          print_name: 'Tel List',        table: 'gigs',
               fields: ['name', 'mobile_no', 'emergency_no'])
  end
  def down
    Report.where(name: 'gr_tel_no').destroy_all
    Report.create!(name: 'gr_tel_no', print_name: 'Applied - Tel List', table: 'gig_requests',
                   fields: ['name', 'home_no', 'mobile_no', 'emergency_no'],
                   row_numbers: true)
    Report.where(name: 'tel_no').destroy_all
    Report.create!(name: 'tel_no',          print_name: 'Tel List',        table: 'gigs',
               fields: ['name', 'home_no', 'mobile_no', 'emergency_no'])
  end
end
