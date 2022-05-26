class UpdateTimeClockReport < ActiveRecord::Migration[5.2]
  def up
    change_column_null :time_clock_reports, :tax_week_id, false
    change_column_null :time_clock_reports, :notes, false
    change_column_null :time_clock_reports, :signed_by_name, false
    change_column_null :time_clock_reports, :signed_by_job_title, false
    change_column_null :time_clock_reports, :signed_by_company_name, false
    change_column :time_clock_reports, :signature, :text
    change_column_default :time_clock_reports, :notes, ''
    change_column_default :time_clock_reports, :signed_by_name, ''
    change_column_default :time_clock_reports, :signed_by_job_title, ''
    change_column_default :time_clock_reports, :signed_by_company_name, ''
    add_column :time_clock_reports, :client_notes, :text, default: '', null: false
    add_column :time_clock_reports, :client_rating, :integer
    add_column :time_clock_reports, :date_submitted, :datetime
  end
  def down 
    change_column_null :time_clock_reports, :tax_week_id, true
    change_column_null :time_clock_reports, :notes, true
    change_column_null :time_clock_reports, :signed_by_name, true
    change_column_null :time_clock_reports, :signed_by_job_title, true
    change_column_null :time_clock_reports, :signed_by_company_name, true
    change_column :time_clock_reports, :signature, :string
    change_column_default :time_clock_reports, :notes, nil
    change_column_default :time_clock_reports, :signed_by_name, nil
    change_column_default :time_clock_reports, :signed_by_job_title, nil
    change_column_default :time_clock_reports, :signed_by_company_name, nil
    remove_column :time_clock_reports, :client_notes
    remove_column :time_clock_reports, :client_rating
    remove_column :time_clock_reports, :date_submitted
  end
end
