# config/environments/production.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Settings specified here will take precedence over those in
# config/application.rb.

# noinspection RubyResolve
Rails.application.configure do

  # Eager load code on boot. This eager loads most of Rails and your
  # application in memory, allowing both threaded web servers and those relying
  # on copy on write to perform better. Rake tasks automatically ignore this
  # option for performance.
  config.eager_load = true

  # Application code remains in memory after being loaded.
  config.cache_classes = true

  # ===========================================================================
  # Security
  # ===========================================================================

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Ensures that a master key has been made available in either
  # ENV['RAILS_MASTER_KEY'] or in config/master.key. This key is used to
  # decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and
  # use secure cookies.
  # config.force_ssl = true

  # ===========================================================================
  # Caching
  # ===========================================================================

  # Caching is turned on.
  config.action_controller.perform_caching = true

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # ===========================================================================
  # Mailer
  # ===========================================================================

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to
  # raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # ===========================================================================
  # I18n
  # ===========================================================================

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # ===========================================================================
  # ActiveSupport
  # ===========================================================================

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # ===========================================================================
  # ActiveRecord
  # ===========================================================================

  # Do not dump schema after migrations in the deployed application.
  config.active_record.dump_schema_after_migration = !application_deployed?

  # ===========================================================================
  # ActiveJob
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # ActionCable
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # ActiveStorage
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # Static files
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # Logging
  # ===========================================================================

  # Prepend all log lines with the following tags.
  config.log_tags = %i[request_id]

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger =
  #   ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if true?(ENV['RAILS_LOG_TO_STDOUT'])
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # ===========================================================================
  # Assets
  # ===========================================================================

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # ===========================================================================
  # Interactive development
  # ===========================================================================

  # N/A

end
