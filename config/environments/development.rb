# config/environments/development.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Settings specified here will take precedence over those in
# config/application.rb.

# noinspection RubyResolve
Rails.application.configure do

  # Do not eager load code on boot.
  config.eager_load = false

  # In the development environment your application's code is reloaded on every
  # request. This slows down response time but is perfect for development since
  # you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # ===========================================================================
  # Security
  # ===========================================================================

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing.
  config.server_timing = true

  # ===========================================================================
  # Caching
  # ===========================================================================

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  # noinspection RubyResolve
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # ===========================================================================
  # Mailer
  # ===========================================================================

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

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

  # Send deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # ===========================================================================
  # ActiveRecord
  # ===========================================================================

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # ===========================================================================
  # ActiveJob
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # ActionCable
  # ===========================================================================

  # See config/application.rb

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # ===========================================================================
  # ActiveStorage
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # Static files
  # ===========================================================================

  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{2.days}"
  }

  # ===========================================================================
  # Logging
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # Assets
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # Interactive development
  # ===========================================================================

  # Use an evented file watcher to asynchronously detect changes in source
  # code, routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
