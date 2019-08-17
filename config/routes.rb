# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true

Rails.application.routes.draw do

  root to: 'home#index'

  # ===========================================================================
  # :section: Home page
  # ===========================================================================

  resources :home, only: %i[index] do
    collection do
      get :welcome
      get :dashboard
    end
  end

  get '/welcome',   to: 'home#welcome',   as: 'welcome'
  get '/dashboard', to: 'home#dashboard', as: 'dashboard'

  # ===========================================================================
  # :section: Category operations
  # ===========================================================================

  resources :category, only: %i[index]

  # ===========================================================================
  # :section: Catalog Title operations
  # ===========================================================================

  resources :title do
    member do
      get 'history'
    end
  end

  # ===========================================================================
  # :section: Periodical operations
  # ===========================================================================

  resources :periodical
  resources :edition

  # ===========================================================================
  # :section: Artifact operations
  # ===========================================================================

  resources :artifact, except: %i[index]

  get '/artifact/:bookshareId/:fmt', to: 'artifact#show', as: 'download'

  # ===========================================================================
  # :section: Organization operations
  # ===========================================================================

  resources :member
  resources :reading_list

  # ===========================================================================
  # :section: Health check
  # ===========================================================================

  resources :health, only: [] do
    collection do
      get :version
      get :check
      get 'check/:subsystem', to: 'health#check', as: 'check_subsystem'
    end
  end

  get '/version',     to: 'health#version'
  get '/healthcheck', to: 'health#check'

  # ===========================================================================
  # :section: Metrics
  # NOTE: "GET /metrics" is handled by Prometheus::Middleware::Exporter
  # ===========================================================================

  get '/metrics/test', to: 'metrics#test'

  # ===========================================================================
  # :section: API test routes
  # ===========================================================================

  resources :api, only: %i[index] do
    collection do
      get   'image',        to: 'api#image'
      # noinspection RailsParamDefResolve
      match 'v2/*api_path', to: 'api#v2', via: %i[get put post delete]
    end
  end

  # noinspection RailsParamDefResolve
  match 'v2/*api_path', to: 'api#v2', as: 'v2_api', via: %i[get put post delete]

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

end

# RubyMine isn't good at using the routes to figure out the implied URL helper
# function names.  This non-functional block gives them definitions so that
# they are not flagged as unknown.
#
unless ONLY_FOR_DOCUMENTATION
  def api_index_path;             api_index_path;             end
  def confirmation_path;          confirmation_path;          end
  def confirmation_url;           confirmation_url;           end
  def dashboard_path;             dashboard_path;             end
  def destroy_user_session_path;  destroy_user_session_path;  end
  def edit_password_url;          edit_password_url;          end
  def new_user_session_path;      new_user_session_path;      end
  def password_path;              password_path;              end
  def registration_path;          registration_path;          end
  def root_url;                   root_url;                   end
  def session_path;               session_path;               end
  def title_index_path;           title_index_path;           end
  def unlock_path;                unlock_path;                end
  def unlock_url;                 unlock_url;                 end
  def welcome_path;               welcome_path;               end
end
