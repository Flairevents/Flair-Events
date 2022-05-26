system "flair_backup"
database_exists = `psql -lqt | cut -d \\| -f 1 | grep 'flair_development'`
database_deleted = true
database_deleted = system "dropdb flair_development" unless database_exists.strip.empty?
if database_deleted
  system "createdb flair_development"
  path = "/Volumes/Backup/flair_backup/shared/db_backups/"
  file_path = Dir.glob("#{path}/*").max_by {|f| File.mtime(f)} 
  dest_path = '/tmp/flair_development.sql'
  system "gunzip -c #{file_path} > #{dest_path}"
  system "psql -d flair_development < #{dest_path}"
  system "rm -f #{dest_path}"
end
