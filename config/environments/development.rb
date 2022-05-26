Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.shared_dir = Rails.root.join('shared')
  config.base_http_url  = 'http://localhost:3000'
  config.base_https_url = 'http://localhost:3000'

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :raise

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Raise errors if unpermitted parameters are mass-assigned
  config.action_controller.action_on_unpermitted_parameters = :raise

  # Bullet Gem
  config.after_initialize do
    Bullet.enable = true         # Enable Bullet Gem
    Bullet.counter_cache_enable = false # Don't check for missing counter caches. I find the counter caches are not reliable
    Bullet.unused_eager_loading_enable = false # Don't check for unused. This happens sometimes when the included table is conditionally used
    Bullet.alert = false         # Popup a Javascript alter in the browser
    Bullet.bullet_logger = false # Log warnings to Rails.root/log/bullet.log
    Bullet.console = false       # Log warnings to browser's console.log
    Bullet.rails_logger = false  # Add warnings directly to the Rails log
    Bullet.raise = true          # Raise errors, useful for making your specs fail unless they have optimized queries
  end

  # Log to console
  logger           = ActiveSupport::Logger.new(STDOUT)
  logger.formatter = config.log_formatter
  config.logger    = ActiveSupport::TaggedLogging.new(logger)

  # For use with WSL 2, if you are using WSL 1 or a VM you can comment this out
  # config.web_console.whitelisted_ips = %x{ip route | awk '/default/{print $3}'}.chomp
end
