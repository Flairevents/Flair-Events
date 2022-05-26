class UpdateBarExpTrainingReport < ActiveRecord::Migration
  def up
    Report.where(name: 'bar_exp_training', table: 'gigs').destroy_all
    Report.create!(name: 'bar_exp_training', print_name: 'Bar Exp/Training', table: 'gigs',
                   fields: ['name', 'email', 'date_of_birth', 'bar_experience', 'bar_license_type', 'bar_license_no', 'bar_license_expiry', 'training_type'],
                   row_numbers: true)
  end

  def down
    Report.where(name: 'bar_exp_training', table: 'gigs').destroy_all
    Report.create!(name: 'bar_exp_training', print_name: 'Bar Exp/Training', table: 'gigs',
                   fields: ['name', 'date_of_birth', 'bar_experience', 'bar_license_type', 'bar_license_no', 'bar_license_expiry', 'training_type'],
                   row_numbers: true)
  end
end
