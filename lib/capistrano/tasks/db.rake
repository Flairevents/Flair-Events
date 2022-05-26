require "rubygems/package"
require "zlib"

namespace :db do

  # Downloads remote DB and imports it locally
  # Notes:
  # 1. It expects the remote db to be named (:application_name)_(:environment), eg: myawesomeapp_production, myawesomeapp_staging, etc
  # 2. The db will be imported to (:application_name)_development
  task :pull do
    on roles :db do |host|
      within current_path do

        # Remote
        file_name = "#{ fetch :application }-#{ fetch :stage }-database-#{ Time.now.strftime "%Y%m%d.%H%M%S" }"
        database  = "#{ file_name }.sql"
        archive   = "#{ file_name }.tgz"
        execute   :pg_dump, "#{ fetch :application }_#{ fetch :stage }", :>, database
        execute   :tar, "-zcf", archive, database
        execute   :rm, "-rf", database
        download! archive, "./#{ archive }"
        execute   :rm, "-rf", archive

        # Local
        local_archive = Gem::Package::TarReader.new Zlib::GzipReader.open(archive)
        local_archive.rewind
        local_archive.each do |entry|
          Dir.mkdir entry.full_name if entry.directory? and !File.exists?(entry.full_name)
          File.write entry.full_name, entry.read if entry.file?
        end
        local_archive.close

        %x(rm -rf #{ archive })
        %x(rails db:drop)
        %x(rails db:create)
        %x(psql #{ fetch :application }_development < #{ database })
        %x(rails db:environment:set)
        %x(rm -rf #{ database })

      end
    end
  end

  # Imports production database into staging on remote
  #
  # Note: Be sure to stop the staging server processes first
  # Note: If an error regarding DB connections arises, drop them by using:
  #   > psql -U deploy flair_staging
  #   > select pg_terminate_backend(pid) from pg_stat_activity where datname='flair_staging';
  task :update_staging do
    on roles :db do |host|
      within current_path do
        file_name = "#{ fetch :application }-#{ fetch :stage }-database-#{ Time.now.strftime "%Y%m%d.%H%M%S" }"
        database  = "#{ file_name }.sql"
        execute   :pg_dump, "#{ fetch :application }", :>, database
        execute   :dropdb, "#{ fetch :application }"
        execute   :createdb, "#{ fetch :application }"
        execute   :psql, "#{ fetch :application }", :<, database
      end
    end
  end

  task :reset_staging_database do
    on roles :db do |host|
      within current_path do
        production_dump = "#{fetch :production_application}-database-#{ Time.now.strftime "%Y%m%d.%H%M%S" }"
        staging_dump = "#{ fetch :application }-database-#{ Time.now.strftime "%Y%m%d.%H%M%S" }"
        execute   :pg_dump, "#{ fetch :production_application }", :>, production_dump
        execute   :pg_dump, "#{ fetch :application }", :>, staging_dump
        execute   :dropdb, "#{ fetch :application }"
        execute   :createdb, "#{ fetch :application }"
        execute   :psql, "#{ fetch :application }", :<, production_dump
      end
    end
  end

  task :production_backup do
    on roles :db do |host|
      within current_path do
        file_name = "#{ fetch :application }-#{ fetch :stage }-database-#{ Time.now.strftime "%Y%m%d.%H%M%S" }"
        database  = "#{ file_name }.sql"
        execute   :pg_dump, "#{ fetch :application }_#{ fetch :stage }", :>, database
      end
    end
  end
end