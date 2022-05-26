class UpdateTaxWeeksPart2 < ActiveRecord::Migration
  def up
    #Remove old constraints
    db.execute "ALTER TABLE tax_weeks DROP CONSTRAINT tax_weeks_prospect_id_tax_week_year_event_id_rate_key"
    remove_index :tax_weeks, :event_id
    #Remove old columns
    remove_column :tax_weeks, :event_id
    remove_column :tax_weeks, :prospect_id
    remove_column :tax_weeks, :job_role
    remove_column :tax_weeks, :work_location
    remove_column :tax_weeks, :shift
    remove_column :tax_weeks, :paid
    remove_column :tax_weeks, :payment_method
    remove_column :tax_weeks, :exported 
    #Add new constraints
    db.execute "ALTER TABLE tax_weeks ALTER COLUMN gig_id SET NOT NULL"
    db.execute "ALTER TABLE tax_weeks ALTER COLUMN shift_id SET NOT NULL"
    db.execute "ALTER TABLE tax_weeks ADD UNIQUE (gig_id, shift_id, tax_year, tax_week)"
  end

  def down
    #Remove new constraints
    db.execute "ALTER TABLE tax_weeks ALTER COLUMN gig_id DROP NOT NULL"
    db.execute "ALTER TABLE tax_weeks ALTER COLUMN shift_id DROP NOT NULL"
    db.execute "ALTER TABLE tax_weeks DROP CONSTRAINT tax_weeks_gig_id_shift_id_tax_year_tax_week"
    #Add back old columns
    add_column :tax_weeks, :event_id, :integer
    add_column :tax_weeks, :prospect_id, :integer
    add_column :tax_weeks, :job_role, :string
    add_column :tax_weeks, :work_location, :string
    add_column :tax_weeks, :shift, :string
    add_column :tax_weeks, :paid, :boolean
    add_column :tax_weeks, :payment_method, :string
    add_column :tax_weeks, :exported, :boolean
    #Add back old constraints
    db.execute "ALTER TABLE tax_weeks ADD UNIQUE (prospect_id, tax_week, tax_year, event_id, rate)"
    add_index :tax_weeks, :event_id
  end
end
