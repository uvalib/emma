# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true

Rails.application.routes.draw do

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  devise_for :users, controllers: {
    sessions:           'user/sessions',
    omniauth_callbacks: 'user/omniauth_callbacks',
  }

  # NOTE: for testing with fixed IDs
  devise_scope :user do
    get '/users/sign_in_as', to: 'user/sessions#sign_in_as', as: 'sign_in_as'
  end

  # ===========================================================================
  # :section: API test routes
  # ===========================================================================

  get   '/api',              to: 'api#index'
  match '/api/v2/*api_path', to: 'api#v2', via: %i[get put post], as: 'api_v2'

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

  resources :home, only: [:index] do
    get :welcome
    get :dashboard
  end

  get '/welcome',   to: 'home#welcome'
  get '/dashboard', to: 'home#dashboard'

  root to: 'home#index'

end
