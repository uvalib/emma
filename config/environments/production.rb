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
  # config.i18n.raise_on_missing_translations = true

  # =========================================================================
  # ActionController
  # =========================================================================

  # See config/application.rb

  # ===========================================================================
  # ActiveSupport
  # ===========================================================================

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # ===========================================================================
  # ActiveRecord
  # ===========================================================================

  # See config/application.rb

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

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # ===========================================================================
  # Assets
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # Interactive development
  # ===========================================================================

  # N/A

end
