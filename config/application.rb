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

    # Initialize configuration defaults.
    config.load_defaults 6.1

    # This is not compatible with the current directory layout:
    # config.add_autoload_paths_to_load_path = false

    # Eager load code on boot.
    config.eager_load = true

    # Code is not reloaded between requests.
    config.cache_classes = true

    # =========================================================================
    # Security
    # =========================================================================

    config.session_store(
      :cookie_store,
      same_site: :lax,
      key:       "#{railtie_name.chomp('_application')}_session"
    )

    # =========================================================================
    # Caching
    # =========================================================================

    # See config/environments/*.rb

    # =========================================================================
    # Mailer
    # =========================================================================

    config.action_mailer.perform_caching = false

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
      Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]

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
    config.active_record.dump_schema_after_migration = !application_deployed?

    # =========================================================================
    # ActionCable
    # =========================================================================

    # Mount Action Cable outside main process or domain.
    # config.action_cable.url = 'wss://example.com/cable'
    # config.action_cable.mount_path = nil
    # config.action_cable.allowed_request_origins =
    #   [ 'http://example.com', /http:\/\/example.*/ ]

    # =========================================================================
    # ActiveJob
    # =========================================================================

    # @see config/initializers/good_job.rb
    config.active_job.queue_adapter = :good_job
    # config.active_job.queue_name_prefix = "emma_#{Rails.env}"
    config.active_job.skip_after_callbacks_if_terminated = !DEBUG_JOB

    # =========================================================================
    # ActiveStorage
    # =========================================================================

    # Store uploaded files on the local file system.
    # (See config/storage.yml for options.)
    config.active_storage.service = :local

    # =========================================================================
    # Static files
    # =========================================================================

    # Disable serving static files from the `/public` folder by default since
    # Apache or NGINX already handles this.
    config.public_file_server.enabled = true?(ENV['RAILS_SERVE_STATIC_FILES'])
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{30.days}"
    }

    # =========================================================================
    # Logging
    # =========================================================================

    # Use the lowest log level to ensure availability of diagnostic information
    # when problems arise.
    config.log_level = CONSOLE_DEBUGGING ? :debug : :info

    # Don't colorize AWS logs.
    config.colorize_logging = !application_deployed?

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
