server 'staging.eventstaffing.co.uk', user: "deploy", roles: %w{app web db}, primary: true

set :application, 'flair_staging'
set :production_application, 'flair_production'
set :domain, 'staging.eventstaffing.co.uk'
set :tmp_dir, '/home/deploy/temp'
set :workers, 1
set :port, 4000

set :rails_env, 'staging'

set :db_config, <<-EOF
    staging:
      adapter: postgresql
      encoding: unicode
      username: deploy
      password: priorityrummagecoup
      database: flair_staging
      min_messages: warning
    EOF

# https://gist.github.com/danielpietzsch/865115
# parses out the current branch you're on. See: http://www.harukizaemon.com/2008/05/deploying-branches-with-capistrano.html
current_branch = `git branch`.match(/\* (\S+)\s/m)[1]

# use the branch specified as a param, then use the current branch. If all fails use master branch
set :branch, ENV['branch'] || current_branch || "hotfix/job" # you can use the 'branch' parameter on deployment to specify the branch you wish to deploy
