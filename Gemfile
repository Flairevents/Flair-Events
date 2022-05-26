source 'https://rubygems.org'

ruby '2.5.5'
gem 'rails', '~> 5.2.3'
gem 'webpacker', '~> 6.x'
gem 'thin'
gem 'pg' # Postrges
gem 'whenever' # For cron jobs
gem 'bcrypt' # Password Hashing (uses OpenBSD bcrypt)
gem 'chronic' # Natural Language Date Parser
gem 'awesome_print' # pretty print objects in IRB. Use 'ap Object'
gem 'phone' # Phone Number parsing, validation, and formatting
gem 'request_store' #Per-request global storage for Rack
gem 'bootsnap', require: false #Bootsnap is a library that plugs into Ruby, with optional support for ActiveSupport and YAML, to optimize and cache expensive computations.
gem 'geocoder' # Geocoding
gem 'spicy-proton' # Random words
#gem 'newrelic_rpm'
# To start maintenance mode: rake maintenance:start
# To end   maintenance mode: rake maintenance:end
# See more info at http://www.oss.io/p/THEY/turnout

#File Handling
gem 'rubyzip' # Read/Write ZIP files
gem 'write_xlsx' # Write Excel XLSX files
gem 'prawn-rails' # Handles and registers PDF formats
gem 'prawn-templates', '~> 0.1.2' # allow PDF inside another PDF
gem 'carrierwave' # File Upload
gem 'mini_magick' # ImageMagick ruby wrapper
gem 'fastimage' # Finds the size or type of an image given its uri by fetching as little as needed

# Javascript / Frontend
gem 'jquery-rails' #jQuery for Rails Asset Pipeline
gem 'jquery-ui-rails' #jQuery UI for Rails Asset Pipeline
gem 'turbolinks'
gem 'webshims-rails' # WebShims Library
gem 'font-awesome-sass' # FontAwesome Icons
gem 'tinymce-rails' # TinyMCE WYSIWYG Editor
gem 'oj' # Fast conversion of Ruby objects to JSON

#Pipeline
gem 'haml'
gem 'haml_coffee_assets' # Compile Haml Coffee Templates in Asset Pipeline
gem 'sprockets', '~> 3.0' # Asset Packaging. Stick to v3 as v4 is still in beta
gem 'sprockets-rails' # Sprocket implementation of Rails Asset Pipeline
gem 'coffee-rails' # Coffeescript support
gem 'sassc-rails' # Sass Support
gem 'uglifier' # Javascript compressor
gem 'psych' # YAML Parser/Emitter
gem 'slim' # Slim templates

# Background jobs/mailing
gem 'delayed_job_active_record' # For running background (async) jobs
gem 'daemons' # Needed for background process which runs Delayed::Job tasks
gem 'sequel' #Sequel: The Database Toolkit for Ruby. Used in unsubscribe.rb
gem 'request-log-analyzer' # Analyze log file to provide metrics
gem 'exception_notification' # Email Unhandled Exceptions
gem 'exception_notification-rake' # Email Unhandled Exceptions in Rake Tasks
gem 'mail' # Ruby Mail Library
gem 'rinku' #Ruby library to convert text that looks like links into links
gem "icalendar" # Ruby library to creat ics calendar email attachments
gem 'sitemap_generator'

group :development do
  gem 'binding_of_caller'
  gem 'web-console'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'byebug'
end

group :development, :test do
  gem 'listen' # Listents to file modifications and notifies you about changes
  gem 'capistrano', '~> 3.0', require: false # Deployment.
  gem 'capistrano-rails', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-thin', require: false
  gem 'capistrano-yarn', require: false
  gem 'capistrano-logrotate', require: false
  gem 'capistrano3-delayed-job', require: false
  gem 'sshkit-sudo', require: false

  gem 'discover-unused-partials' # Find unused partial views
  gem 'localtunnel' # Share local running dev server (useful for testing in VM)
  # To use localtunnel do:
  # terminal 1> rails server -b 0.0.0.0 -p 3000
  # terminal 2> lt -p 3000
  # navigate to the URL printed by the last command
  gem 'guard' # Handle Events on File System Modifications
  gem 'guard-rake' # Run a rake task when a file changes
  gem 'rack-mini-profiler' # Profiler
  gem 'flamegraph' # Flame Graphs for Profiler
  gem 'stackprof' # Stack Profiler
  gem 'memory_profiler' # Memory Profiler
  gem 'rubocop', require: false # Static Code Analyzer
  gem 'bullet' # Notify of potentially unneccessary db queries
  gem 'rb-readline'
  gem 'pry' # better REPL
  gem 'pry-coolline' # Required by pry
end

group :test do
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'debug_inspector'
  gem 'parser'
  gem 'rouge'
end

group :production do
  #gem 'skylight' #Performance Monitoring Tool (www.skylight.io)
end

# v2
gem 'kaminari' # pagination
gem 'browser', '2.0.3'
