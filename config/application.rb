require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Flair
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # NOTE: If you don't increment this, you will not get new defaults for
    # new rails versions
    config.load_defaults 5.2

    # Rails 5.2 defaults protect_from_forgery to an exception, which we don't want,
    # since csrf tokens can get invalid if the user loads a form before a site update
    # then submits the form after a site update. We will continue to manually
    # use the old behavior by calling protect_from_forgery in the application controller,
    # which defaults to :null_session instead of :exception
    config.action_controller.default_protect_from_forgery = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.time_zone = 'London'

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.active_record.schema_format = :sql

    # HAML Coffee templates can appear anywhere in assets/javascripts
    config.hamlcoffee.name_filter = lambda { |n| n }

    config.active_job.queue_adapter = :delayed_job

    #Time columns will become time zone aware in Rails 5.1. This
    #still causes `String`s to be parsed as if they were in `Time.zone`,
    #and `Time`s to be converted to `Time.zone`.
    #To keep the old behavior, you must add the following to your initializer:
    config.active_record.time_zone_aware_types = [:datetime]
    #To silence this deprecation warning, add the following:
    #config.active_record.time_zone_aware_types = [:datetime, :time]
  end
end
