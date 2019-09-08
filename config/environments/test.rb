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

Rails.application.configure do

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

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

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # ===========================================================================
  # ActiveSupport
  # ===========================================================================

  # Send deprecation notices to STDERR.
  config.active_support.deprecation = :stderr

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

end
