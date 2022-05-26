server 'eventstaffing.co.uk', user: "deploy", roles: %w{app web db}, primary: true

set :application, 'flair'

set :domain, 'eventstaffing.co.uk'
set :tmp_dir, '/home/deploy/temp'

set :workers, 6
set :port, 3000

set :rails_env, 'production'

set :nginx_pidfile, '/run/nginx.pid'

set :db_config, <<-EOF
    production:
      adapter: postgresql
      encoding: unicode
      username: deploy
      password: priorityrummagecoup
      database: flair_production
      min_messages: warning
    EOF

namespace :deploy do
  desc "Create Nginx config file"
  task :create_nginx_config do
    nginxconf = ERB.new(File.read(File.expand_path('../templates/nginx.conf.erb', __dir__))).result(binding)
    on roles(:app) do
      upload! StringIO.new(nginxconf), "/tmp/nginx.conf"
      sudo "mv /tmp/nginx.conf /etc/nginx/nginx.conf"
      sudo "/etc/init.d/nginx reload"
    end
  end

  after :publishing, :create_nginx_config
end
