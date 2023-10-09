# config/initializers/cors.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for the rack-cors gem.
#
# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin
# AJAX requests. Read more: https://github.com/cyu/rack-cors

CORS_OPT = { debug: DEBUG_CORS }

Rails.application.config.middleware.insert_before 0, Rack::Cors, CORS_OPT do

  # === UVA clients
  allow do
    origins  *ActionCable.server.config.allowed_request_origins
    resource '*', headers: :any, methods: :any
  end

  # === Openly available search results
  allow do
    origins  '*'
    resource '/search/*', headers: :any, methods: %i[get head options]
  end

end
