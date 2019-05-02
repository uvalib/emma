# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true

Rails.application.routes.draw do

  # ===========================================================================
  # :section: OAuth2
  # ===========================================================================

  match 'auth/callback', to: 'auth#callback', via: %i[get post]

  # ===========================================================================
  # :section: API test routes
  # ===========================================================================

  get '/api', to: 'api#index'

  # ===========================================================================
  # :section: Metrics
  # NOTE: "GET /metrics" is handled by Prometheus::Middleware::Exporter
  # ===========================================================================

  get '/metrics/test', to: 'metrics#test'

  # ===========================================================================
  # :section: Health check
  # ===========================================================================

  get '/health/check/:subsystem', to: 'health#check'
  get '/health/check',            to: 'health#check'
  get '/health/version',          to: 'health#version'

  get '/healthcheck', to: 'health#check'
  get '/version',     to: 'health#version'

  # ===========================================================================
  # :section: Home page
  # ===========================================================================

  root to: 'api#index'

end
