require "capistrano/setup"
require "capistrano/deploy"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require "capistrano/rails"
require "capistrano/delayed_job"
require "capistrano/thin"
require "whenever/capistrano"
require "capistrano/yarn"
require "capistrano/logrotate"
require "capistrano/bundler"
#require 'new_relic/recipes'
require 'capistrano/sitemap_generator'

require "sshkit/sudo"

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }