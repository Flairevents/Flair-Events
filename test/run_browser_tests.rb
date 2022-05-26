require 'yaml'
require 'sequel'

require_relative 'framework'
require_relative 'browser/common'
require_relative '../lib/process_utils'

extend Flair::Processes

print "Killing Thin... "
kill('/tmp/pids/thin-test.pid')
kill('/tmp/pids/thin-dev.pid')
puts "Done."

# launch main app in test mode
print "Starting Thin... "
$thin_pid = pid("bundle exec thin --port=3000 --daemonize --environment=test --pid=/tmp/pids/thin-test.pid --log=/tmp/thin-test.log --rackup=\"#{File.expand_path('../config.ru', __dir__)}\" start",
                '/tmp/pids/thin-test.pid')
puts "Done, PID: #{$thin_pid}"

# Each suite of browser tests will recreate the test DB, open a connection to it,
#   then close the connection when done
# Originally, the idea was to use one connection to the DB, wrap all tests in DB
#   transactions, then roll back the transactions to restore the DB state
# This doesn't work because we are relying on PG LISTEN and NOTIFY, and PG notifications
#   are only sent when changes are *committed*
# Fortunately, it turns out that recreating a PG DB from a template is very fast
# We have a DB called flair_test_pristine for use as a template. It is initialized by
#   running test/create_test_db.rb
db_config = YAML.load_file(File.expand_path('../config/database.yml', __dir__))
open_db = lambda do
  Sequel.connect(db_config['test'].merge('database' => 'postgres')) do |db|
    db.execute "DROP DATABASE IF EXISTS #{db_config['test']['database']}"
    db.execute "CREATE DATABASE #{db_config['test']['database']} TEMPLATE flair_test_pristine"
  end
  Sequel.connect(db_config['test'])
end

session = Capybara::Session.new(:selenium_chrome)

Dir["#{__dir__}/browser/test_*.rb"].each { |file| load(file) }
browser_suites = []
browser_suites << TestEventsTab.new(session, open_db)

runner = Flair::Test::Runner.new(browser_suites)
runner.on_failure(:launch_repl)
status = runner.run

# clean up
#`kill #{$thin_pid}`
#cmd('dropdb --if-exists flair_test')

Kernel.exit(status)
