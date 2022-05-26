# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :repo_url,  "ssh://git@gitlab.com/flaireventstaffing/website.git"

set :user, 'deploy'

set :group, 'group'

set :ssh_options, {
  user: fetch(:user),
  keys: %w('~/.ssh/id_rsa.pub'),
  auth_methods: %w(publickey password),
  forward_agent: true,
  password: ENV['FLAIR_SUDO_PASSWORD']
}

set :pty, true

append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system",
                     "public/event_photos", "public/bulk_interview_photos",
                     "public/content_thumbnails", ".bundle"

set :keep_releases, 3

set :keep_assets,   3

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :bundle_flags, '--deployment' #### Default is --deployment --quiet
set :yarn_flags, '--production' ##### Default is '--production --silent --no-progress'

# This logrotate template will be used to create a separate config file for each
#   environment, which will go under /etc/logrotate.d
# It does *not* create the main /etc/logrotate.conf file
set :logrotate_template_path, File.expand_path('templates/logrotate.conf.erb', __dir__)
set :logrotate_interval, 'weekly'

namespace :deploy do

  desc "Create the database yaml file"
  task :create_database_yml do
    on roles(:app) do
      upload! StringIO.new(fetch(:db_config)), release_path.join("config/database.yml")
    end
  end

  desc "Create Thin Config File"
  task :create_thin_config do
    on roles(:app) do
      config = ERB.new(File.read("config/templates/thin_conf.yml.erb")).result(binding)
      execute :mkdir, '-p', release_path.join("config/thin")
      upload! StringIO.new(config), release_path.join("config/thin/#{fetch(:rails_env)}.yml")
    end
  end

  desc "Manually Start Thin Server and Delayed Job"
  task :start do
    invoke 'thin:start'
    invoke 'delayed_job:start'
  end

  desc "Manually Restart Thin Server and Delayed Job"
  task :restart do
    invoke 'thin:restart' 
    invoke 'delayed_job:restart'
  end

  desc "Manually Stop Thin Server and Delayed Job"
  task :stop do
    invoke 'thin:stop'
    invoke 'delayed_job:stop'
  end
  
  after :updating, :create_database_yml
  after :updated, :create_thin_config
  #after :updated, "newrelic:notice_deployment"
  after :publishing, 'thin:restart'
  if fetch(:stage) == :production
    after 'deploy:published', 'sitemap:refresh'
  end

end

namespace :remote do
  desc "Run a task on a remote server."
  # run like: cap staging remote:task task=metabolites:update
  task :task do
    on roles(:app) do
      within current_path do
        execute :rake, ENV['task'], "RAILS_ENV=#{fetch(:stage).to_s}"
      end
    end
  end
end

# Customize sshkit-sudo to automatically use password in ssh_options
# It doesn't have any feature like this built-in; try to contribute code so
#   this custom code can be deleted
class SSHKit::Sudo::InteractionHandler
  def on_data(command, stream_name, data, channel)
    if data =~ /Sorry.*\stry\sagain/
      raise "Wrong sudo password"
    end
    if data =~ /[Pp]assword.*:/
      channel.send_data(command.host.ssh_options[:password] + "\n")
    end
  end
end
