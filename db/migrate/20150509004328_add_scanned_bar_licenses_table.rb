class AddScannedBarLicensesTable < ActiveRecord::Migration
  def up
    create_table :scanned_bar_licenses do |t|
      t.integer :prospect_id, null: false
      t.string  :photo, null: false # filename, relative to /var/www/flair/shared/scanned_ids
      # Unlike the library and event photos, scanned_ids is NOT symlinked to our public
      #   directory. Otherwise, anyone on the Internet could view the scanned IDs!

      t.timestamps
    end
    add_index :scanned_bar_licenses, :prospect_id
  end

  def down
    drop_table :scanned_bar_licenses
  end
end
