# config/application.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Settings in config/environments/* take precedence over those specified here.
# Application configuration can go into files in config/initializers -- all .rb
# files in that directory are automatically loaded after loading the framework
# and any gems in your application.

require_relative 'boot'

require 'rails/all'
require 'good_job/engine'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Emma

  # noinspection RubyResolve
  class Application < Rails::Application

    # Bring in application-specific methods and constants.
    add_lib_to_load_path!(Rails.root)
    require 'emma'

    # Initialize configuration defaults.
    config.load_defaults 7.1

    # Eager load code on boot.
    config.eager_load = true

    # Code is not reloaded between requests.
    config.cache_classes = true

    # =========================================================================
    # Security
    # =========================================================================

    config.session_store(
      :active_record_store,
      key: "#{railtie_name.chomp('_application')}_session"
    )

    # =========================================================================
    # Caching
    # =========================================================================

    config.cache_store = [:file_store, CACHE_DIR]

    # =========================================================================
    # Mailer
    # =========================================================================

    config.action_mailer.perform_caching    = false
    config.action_mailer.perform_deliveries = application_deployed?
    config.action_mailer.show_previews      = true

    config.action_mailer.smtp_settings = {
      port:    ENV_VAR['SMTP_PORT'].to_i,
      address: ENV_VAR['SMTP_DOMAIN'],
    }

    config.action_mailer.default_url_options = {
      host:     MAILER_URL_HOST,
      protocol: MAILER_URL_HOST.include?('localhost') ? :http : :https,
    }

    # Specifies the header that your server uses for sending files.
    # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
    # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

    # =========================================================================
    # I18n
    # =========================================================================

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back
    # to the I18n.default_locale when a translation cannot be found).
    config.i18n.fallbacks = true

    # Specify I18n load paths for entire directory hierarchy.
    config.i18n.load_path +=
      Dir[Rails.root.join('config/locales/**/*.{rb,yml}').to_s]

    # =========================================================================
    # ActionController
    # =========================================================================

    # NOTE: Needed for "javascript:history.back()" for now.
    config.action_controller.raise_on_open_redirects = false

    # =========================================================================
    # ActiveSupport
    # =========================================================================

    # See config/environments/*.rb

    # =========================================================================
    # ActiveRecord
    # =========================================================================

    # Inserts middleware to perform automatic connection switching.
    # The `database_selector` hash is used to pass options to the
    # DatabaseSelector middleware. The `delay` is used to determine how long to
    # wait after a write to send a subsequent read to the primary.
    #
    # The `database_resolver` class is used by the middleware to determine
    # which database is appropriate to use based on the time delay.
    #
    # The `database_resolver_context` class is used by the middleware to set
    # timestamps for the last write to the primary. The resolver uses the
    # context class timestamps to determine how long to wait before reading
    # from the replica.
    #
    # By default Rails will store a last write timestamp in the session. The
    # DatabaseSelector middleware is designed as such you can define your own
    # strategy for connection switching and pass that into the middleware
    # through these configuration options.
    # config.active_record.database_selector = { delay: 2.seconds }
    # config.active_record.database_resolver =
    #   ActiveRecord::Middleware::DatabaseSelector::Resolver
    # config.active_record.database_resolver_context =
    #   ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

    # Do not dump schema after migrations in the deployed application.
    config.active_record.dump_schema_after_migration = not_deployed?

    # Raise an error on page load if there are pending migrations.
    config.active_record.migration_error = :page_load if not_deployed?

    # =========================================================================
    # ActionCable
    # =========================================================================

    # Mount Action Cable outside main process or domain.
    #
    # NOTE: As of 2023-03-31, the Terraform configuration for EMMA under
    #   production/federated-authproxy/*/apache/03-emma.conf and
    #   staging/federated-authproxy/*/apache/03-emma-dev.conf defines ProxyPass
    #   such that HTTP_HOST and SERVER_NAME in this application have values of
    #   'emma-production.private.production' and 'emma-staging.private.staging'
    #   (HTTP_X_FORWARDED_HOST will have the actual externally-visible name).

    config.action_cable.allowed_request_origins = [
      %r{^https?://.+-(production|staging)\.private\.\1(:\d+)?$},
      %r{^https?://.+\.virginia\.edu(:\d+)?$},
      %r{^https?://localhost(:\d+)?$},
    ]

    # =========================================================================
    # ActiveJob
    # =========================================================================

    # @see config/initializers/good_job.rb
    config.active_job.queue_adapter = :good_job
    # config.active_job.queue_name_prefix = "emma_#{Rails.env}"
=begin # NOTE: deprecated in Rails 7.1
    config.active_job.skip_after_callbacks_if_terminated = !DEBUG_JOB
=end

    # =========================================================================
    # ActiveStorage
    # =========================================================================

    # Store uploaded files on the local file system.
    # (See config/storage.yml for options.)
    config.active_storage.service = :local

    # =========================================================================
    # Static files
    # =========================================================================

    config.public_file_server.enabled = RAILS_SERVE_STATIC_FILES
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{30.days}"
    }

    # =========================================================================
    # Logging
    # =========================================================================

    # Use the lowest log level to ensure availability of diagnostic information
    # when problems arise.
    config.log_level = CONSOLE_DEBUGGING ? :debug : :info

    # Use default formatter so that PID and timestamp are not suppressed.
    config.log_formatter = Emma::Logger::Formatter.new

    # Don't colorize AWS logs.
    config.colorize_logging = not_deployed?

    # Use a custom logger to support log suppression.
    config.logger = Emma::Logger.new

    # =========================================================================
    # Assets
    # =========================================================================

    # See config/initializers/assets.rb

    # =========================================================================
    # Interactive development
    # =========================================================================

    # See config/environments/development.rb

  end

end
