# config/initializers/cors.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for the rack-cors gem.

CORS_OPT = { debug: DEBUG_CORS }

Rails.application.config.middleware.insert_before 0, Rack::Cors, CORS_OPT do

  # == UVA clients
  allow do
    origins  %r{^https?://.*\.virginia\.edu(:\d+)?$}, 'localhost'
    resource '*', headers: :any, methods: :any
  end

  # == Openly available search results
  allow do
    origins  '*'
    resource '/search/*', headers: :any, methods: %i[get head options]
  end

end