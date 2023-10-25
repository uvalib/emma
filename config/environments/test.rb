# config/environments/test.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Settings specified here will take precedence over those in
# config/application.rb.
#
# The test environment is used exclusively to run your application's test
# suite. You never need to work with it otherwise. Remember that your test
# database is "scratch space" for the test suite and is wiped and recreated
# between test runs. Don't rely on the data there!

# noinspection RubyResolve
Rails.application.configure do

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  #
  # NOTE: In fact, UploadWorkflow won't resolve properly without eager loading.
  #   This might not be an issue in the long run, since the intention is to
  #   eliminate the 'workflow' gem when transitioning from Upload -> Entry
  #   but for now eager loading is required for comprehensive tests.  (Besides
  #   which, it's unclear whether eager loading is actually having a negative
  #   impact in any testing scenario.)
  #
  #config.eager_load = false

  # Application code remains in memory after being loaded.
  config.cache_classes = true

  # ===========================================================================
  # Security
  # ===========================================================================

  # Show full error reports.
  config.consider_all_requests_local = true

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = :none

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # ===========================================================================
  # Caching
  # ===========================================================================

  # Disable caching.
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # ===========================================================================
  # Mailer
  # ===========================================================================

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # ===========================================================================
  # I18n
  # ===========================================================================

  # Raises error for missing translations.
  # config.i8n.raise_on_missing_translations = true

  # =========================================================================
  # ActionController
  # =========================================================================

  # See config/application.rb

  # ===========================================================================
  # ActiveSupport
  # ===========================================================================

  # Send deprecation notices to STDERR.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # ===========================================================================
  # ActiveRecord
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # ActiveJob
  # ===========================================================================

  config.active_job.queue_adapter = :test

  # ===========================================================================
  # ActionCable
  # ===========================================================================

  # See config/application.rb

  # ===========================================================================
  # ActiveStorage
  # ===========================================================================

  # Store uploaded files on the local file system in a temporary directory.
  # (See config/storage.yml for options.)
  config.active_storage.service = :test

  # ===========================================================================
  # Static files
  # ===========================================================================

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour}"
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

  # N/A

end
