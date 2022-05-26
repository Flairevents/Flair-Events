class RenameTransportsToTags < ActiveRecord::Migration[5.1]
  def up
    remove_column :transports, :cost
    execute "DROP TRIGGER normalize_transport_name ON transports"
    execute "ALTER TABLE transports DROP CONSTRAINT transports_name_check"
    execute "ALTER TABLE gigs DROP CONSTRAINT gigs_transport_id_fkey"
    rename_table :transports, :tags
    rename_column :gigs, :transport_id, :tag_id
    execute <<-SQL
      CREATE TRIGGER normalize_tag_name
      BEFORE INSERT OR UPDATE ON tags
      FOR EACH ROW EXECUTE PROCEDURE normalize_name();
    SQL
    execute "ALTER TABLE tags ADD CONSTRAINT tags_name_check CHECK (((name)::text <> ''::text))"
    execute <<-SQL
      ALTER TABLE ONLY gigs
      ADD CONSTRAINT gigs_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES tags(id) MATCH FULL;
    SQL
    Report.where(name: 'reg_sheet', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet', print_name: 'Reg Sheet', table: 'gigs',
                   fields: ['name', 'job_name', 'shift_times', 'location', 'tag', 'mobile_no', 'notes', 'email'],
                   row_numbers: true)
  end
  def down
    execute "ALTER TABLE gigs DROP CONSTRAINT gigs_tag_id_fkey"
    execute "DROP TRIGGER normalize_tag_name ON tags"
    execute "ALTER TABLE tags DROP CONSTRAINT tags_name_check"
    rename_table :tags, :transports
    rename_column :gigs, :tag_id, :transport_id
    add_column :transports, :cost, :decimal, null: false, default: 0
    execute <<-SQL
      CREATE TRIGGER normalize_transport_name
      BEFORE INSERT OR UPDATE ON transports
      FOR EACH ROW EXECUTE PROCEDURE normalize_name();
    SQL
    execute "ALTER TABLE transports ADD CONSTRAINT transports_name_check CHECK (((name)::text <> ''::text))"
    execute <<-SQL
      ALTER TABLE ONLY gigs
      ADD CONSTRAINT gigs_transport_id_fkey FOREIGN KEY (transport_id) REFERENCES transports(id) MATCH FULL;
    SQL
    Report.where(name: 'reg_sheet', table: 'gigs').destroy_all
    Report.create!(name: 'reg_sheet', print_name: 'Reg Sheet', table: 'gigs',
                   fields: ['name', 'job_name', 'shift_times', 'location', 'transport', 'mobile_no', 'notes', 'email'],
                   row_numbers: true)
  end
end
