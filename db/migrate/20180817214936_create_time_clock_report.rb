class CreateTimeClockReport < ActiveRecord::Migration[5.2]
  def change
    create_table :time_clock_reports do |t|
      t.integer :event_id, required: true
      t.date    :date, required: true
      t.string  :submitted_by_email, required: true
      t.integer :tax_week_id, required: true
      t.string  :status, required: true
      t.text    :notes
      t.string  :signed_by_name
      t.string  :signed_by_job_title
      t.string  :signed_by_company_name
      t.string  :signature
      t.timestamps
    end
    add_index :time_clock_reports, [:event_id, :date, :submitted_by_email], unique: true, name: 'index_time_clock_reports_on_event_date_submitted_by'
  end
end
