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

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Emma

  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # =========================================================================
    # SASS
    # =========================================================================

    # NOTE: As of Rails 6, this causes a segfault in "rake assets:precompile".
    # config.sass.inline_source_maps = true

  end

end
