class AddDbsCertificateNumberToProspects < ActiveRecord::Migration[5.2]
  def change
    
    add_column :prospects, :dbs_certificate_number, :string

    create_table :scanned_dbses do |t|
      t.references :prospect, null: false
      t.string  :photo, null: false # filename, relative to /var/www/flair/shared/scanned_ids
      # Unlike the library and event photos, scans are NOT symlinked to our public
      #   directory. Otherwise, anyone on the Internet could view the scanned IDs!

      t.timestamps
    end

  end
end
