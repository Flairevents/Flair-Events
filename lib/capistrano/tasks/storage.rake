require "active_support"

namespace :storage do

  # Downloads all assets in the 'shared' folder on remote host to our development machine
  task :pull do
    start_time = Time.now
    on roles :db do | host |
      within shared_path do
        # We use rsync to sync folders from the shared_path in production on our development machine.

        # remote shared/:folder -> local shared/:folder
        [:prospect_photos, :scanned_ids, :scanned_ids_large].each do |folder|
          sync_start_time = Time.now
          %x(rsync -az #{ host.user }@#{ host.hostname }:#{ shared_path }/#{ folder.to_s } ./shared)
          puts "#{ ActiveSupport::Inflector.humanize folder.to_s } sync time: #{ (Time.now - sync_start_time).to_i } seconds"
        end

        # remote shared/public/:folder -> local public/:folder
        [:event_photos].each do |folder|
          sync_start_time = Time.now
          %x(rsync -az #{ host.user }@#{ host.hostname }:#{ shared_path }/public/#{ folder.to_s } ./public)
          puts "#{ ActiveSupport::Inflector.humanize folder.to_s } sync time: #{ (Time.now - sync_start_time).to_i } seconds"
        end
      end
    end
    puts "Total sync time: #{ (Time.now - start_time).to_i } seconds"
  end

  # Downloads prospects_photos from the 'shared' folder on remote and places it locally under app_root/shared
  task :pull_prospects_photos do
    start_time = Time.now
    on roles :db do | host |
      within shared_path do
        %x(rsync -az #{host.user}@#{host.hostname}:#{ shared_path }/prospect_photos ./shared)
      end
    end
    puts "Total sync time: #{ (Time.now - start_time).to_i } seconds"
  end

  # Downloads scanned_ids from the 'shared' folder on remote and places it locally under app_root/shared
  task :pull_scanned_ids do
    start_time = Time.now
    on roles :db do | host |
      within shared_path do
        %x(rsync -az #{host.user}@#{host.hostname}:#{ shared_path }/scanned_ids ./shared)
      end
    end
    puts "Total sync time: #{ (Time.now - start_time).to_i } seconds"
  end

  # Downloads scanned_ids_large from the 'shared' folder on remote and places it locally under app_root/shared
  task :pull_scanned_ids_large do
    start_time = Time.now
    on roles :db do | host |
      within shared_path do
        %x(rsync -az #{host.user}@#{host.hostname}:#{ shared_path }/scanned_ids_large ./shared)
      end
    end
    puts "Total sync time: #{ (Time.now - start_time).to_i } seconds"
  end

  # Downloads event_photos from the 'shared/public' folder on remote and places it locally under app_root/public
  task :pull_event_photos do
    start_time = Time.now
    on roles :db do | host |
      within shared_path do
        %x(rsync -az #{host.user}@#{host.hostname}:#{ shared_path }/public/event_photos ./public)
      end
    end
    puts "Total sync time: #{ (Time.now - start_time).to_i } seconds"
  end

end
