# config/initializers/silencer.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for the silencer gem.

if LOG_SILENCER

  require 'silencer/rails/logger'

  Rails.application.configure do
    config.middleware.swap(
      Rails::Rack::Logger,
      Silencer::Logger,
      config.log_tags,
      silence: LOG_SILENCER_ENDPOINTS
    )
  end

end
