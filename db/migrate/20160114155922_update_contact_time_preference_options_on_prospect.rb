class UpdateContactTimePreferenceOptionsOnProspect < ActiveRecord::Migration
  def up
    remove_column :prospects, :preferred_contact_time
    add_column :prospects, :prefers_morning, :boolean
    add_column :prospects, :prefers_afternoon, :boolean
    add_column :prospects, :prefers_early_evening, :boolean
    add_column :prospects, :prefers_midweek, :boolean
    add_column :prospects, :prefers_weekend, :boolean
  end
  def down
    add_column :prospects, :prefers_early_evening
    remove_column :prospects, :prefers_morning
    remove_column :prospects, :prefers_afternoon
    remove_column :prospects, :prefers_early_evening
    remove_column :prospects, :prefers_midweek
    remove_column :prospects, :prefers_weekend
  end
end
