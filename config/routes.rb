# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true

Rails.application.routes.draw do

  ALL_METHODS ||= %i[get put post patch delete].freeze

  # ===========================================================================
  # Home page
  # ===========================================================================

  root 'home#main'

  resource :home, controller: 'home', as: '', only: [] do
    get :main, as: 'home'
    get :welcome
    get :dashboard
  end

  # ===========================================================================
  # Category operations
  # ===========================================================================

  resources :category, only: %i[index]

  # ===========================================================================
  # Catalog Title operations
  # ===========================================================================

  resources :title do
    member do
      get :history
    end
  end

  # ===========================================================================
  # Periodical operations
  # ===========================================================================

  resources :periodical
  resources :edition

  get '/edition/:editionId/:fmt?seriesId=:seriesId',
      to: 'edition#download', as: 'edition_download'

  # ===========================================================================
  # Artifact operations
  # ===========================================================================

  resources :artifact, except: %i[index]

  get '/artifact/:bookshareId/:fmt', to: 'artifact#download', as: 'download'

  # ===========================================================================
  # Organization operations
  # ===========================================================================

  resources :member
  resources :reading_list

  # ===========================================================================
  # Health check
  # ===========================================================================

  resource :health, controller: 'health', only: [] do
    get :version
    get :check
    get 'check/:subsystem', to: 'health#check', as: 'check_subsystem'
  end

  get '/version',     to: 'health#version'
  get '/healthcheck', to: 'health#check'

  # ===========================================================================
  # Metrics
  # NOTE: "GET /metrics" is handled by Prometheus::Middleware::Exporter
  # ===========================================================================

  get '/metrics/test', to: 'metrics#test'

  # ===========================================================================
  # API test routes
  # ===========================================================================

  resources :api, only: %i[index] do
    collection do
      # noinspection RailsParamDefResolve
      match 'v2/*api_path', to: 'api#v2', via: ALL_METHODS
      get   :image,         to: 'api#image'
    end
  end

  # noinspection RailsParamDefResolve
  match 'v2/*api_path', to: 'api#v2',    as: 'v2_api',    via: ALL_METHODS
  get   'api/image',    to: 'api#image', as: 'image_api'

  # ===========================================================================
  # Authentication
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

# Non-functional hints for RubyMine.
# :nocov:
unless ONLY_FOR_DOCUMENTATION
  def api_index_path(*);                          end
  def api_index_url(*);                           end
  def artifact_index_path(*);                     end
  def artifact_index_url(*);                      end
  def category_index_path(*);                     end
  def category_index_url(*);                      end
  def check_health_path(*);                       end
  def check_health_url(*);                        end
  def check_subsystem_health_path(*);             end
  def check_subsystem_health_url(*);              end
  def confirmation_path(*);                       end
  def confirmation_url(*);                        end
  def dashboard_path(*);                          end
  def dashboard_url(*);                           end
  def destroy_user_session_path(*);               end
  def destroy_user_session_url(*);                end
  def edit_password_path(*);                      end
  def edit_password_url(*);                       end
  def edition_index_path(*);                      end
  def edition_index_url(*);                       end
  def member_index_path(*);                       end
  def member_index_url(*);                        end
  def metrics_test_path(*);                       end
  def metrics_test_url(*);                        end
  def new_user_session_path(*);                   end
  def new_user_session_url(*);                    end
  def password_path(*);                           end
  def password_url(*);                            end
  def periodical_index_path(*);                   end
  def periodical_index_url(*);                    end
  def reading_list_index_path(*);                 end
  def reading_list_index_url(*);                  end
  def registration_path(*);                       end
  def registration_url(*);                        end
  def root_path(*);                               end
  def root_url(*);                                end
  def session_path(*);                            end
  def session_url(*);                             end
  def title_index_path(*);                        end
  def title_index_url(*);                         end
  def unlock_path(*);                             end
  def unlock_url(*);                              end
  def user_bookshare_omniauth_authorize_path(*);  end
  def user_bookshare_omniauth_authorize_url(*);   end
  def version_health_path(*);                     end
  def version_health_url(*);                      end
  def welcome_path(*);                            end
  def welcome_url(*);                             end
end
# :nocov:
