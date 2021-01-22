# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true

# noinspection LongLine
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
  # EMMA Unified Search operations
  # ===========================================================================

  get '/search/advanced', to: 'search#advanced', as: 'advanced_search'
  get '/search/api',      to: 'search#direct'
  get '/search/direct',   to: 'search#direct'

  resources :search, only: %i[index show]

  # ===========================================================================
  # File upload operations
  #
  # NOTE: Avoid "resources :upload" because :action can get turned into :id.
  # ===========================================================================

  get    '/upload/admin',         to: 'upload#admin',         as: 'admin_upload'

  # === UploadWorkflow::Single

  get    '/upload/new_select',    redirect('/upload/new'),    as: 'new_select_upload'     # Only for consistency
  get    '/upload/new',           to: 'upload#new',           as: 'new_upload'
  match  '/upload/create',        to: 'upload#create',        as: 'create_upload',        via: %i[post put patch]

  get    '/upload/edit_select',   to: 'upload#edit',          as: 'edit_select_upload',   defaults: { id: 'SELECT' }
  get    '/upload/edit/:id',      to: 'upload#edit',          as: 'edit_upload'
  match  '/upload/update/:id',    to: 'upload#update',        as: 'update_upload',        via: %i[put patch]

  get    '/upload/delete_select', to: 'upload#delete',        as: 'delete_select_upload', defaults: { id: 'SELECT' }
  get    '/upload/delete/:id',    to: 'upload#delete',        as: 'delete_upload'
  delete '/upload/destroy/:id',   to: 'upload#destroy',       as: 'destroy_upload'

  # === UploadWorkflow::Bulk

  get    '/upload/bulk_new',      to: 'upload#bulk_new',      as: 'bulk_new_upload'
  post   '/upload/bulk',          to: 'upload#bulk_create',   as: 'bulk_create_upload'

  get    '/upload/bulk_edit',     to: 'upload#bulk_edit',     as: 'bulk_edit_upload'
  match  '/upload/bulk',          to: 'upload#bulk_update',   as: 'bulk_update_upload',   via: %i[put patch]

  get    '/upload/bulk_delete',   to: 'upload#bulk_delete',   as: 'bulk_delete_upload'
  delete '/upload/bulk',          to: 'upload#bulk_destroy',  as: 'bulk_destroy_upload'

  get    '/upload/bulk',          to: 'upload#bulk_index',    as: 'bulk_upload_index'

  # === UploadWorkflow

  post   '/upload/renew',         to: 'upload#renew',         as: 'renew_upload'
  post   '/upload/reedit',        to: 'upload#reedit',        as: 'reedit_upload'
  match  '/upload/cancel',        to: 'upload#cancel',        as: 'cancel_upload',        via: %i[get post]
  get    '/upload/check/:id',     to: 'upload#check',         as: 'check_upload'
  post   '/upload/endpoint',      to: 'upload#endpoint',      as: 'uploads'               # Invoked from file-upload.js

  # === Display

  get    '/upload/show/:id',      to: 'upload#show',          as: 'show_upload'
  get    '/upload',               to: 'upload#index',         as: 'upload_index'

  # ===========================================================================
  # File download operations
  # ===========================================================================

  get '/download/:id', to: 'upload#download',  as: 'file_download'
  get '/retrieval',    to: 'upload#retrieval', as: 'retrieval'

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

  get '/artifact/retrieval',          to: 'artifact#retrieval', as: 'bs_retrieval'
  get '/artifact/:bookshareId/:fmt',  to: 'artifact#download',  as: 'bs_download'

  resources :artifact, except: %i[index]

  # ===========================================================================
  # Organization operations
  # ===========================================================================

  resources :member
  resources :reading_list

  # ===========================================================================
  # Help
  # ===========================================================================

  resources :help, only: %i[index show]

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
  #
  # NOTE: "GET /metrics" is handled by Prometheus::Middleware::Exporter
  # ===========================================================================

  get '/metrics/test', to: 'metrics#test'

  # ===========================================================================
  # API test routes
  # ===========================================================================

  resources :api, only: %i[index] do
    collection do
      match 'v2/*api_path', to: 'api#v2', via: ALL_METHODS
      get   :image,         to: 'api#image'
    end
  end

  match '/v2/*api_path', to: 'api#v2',    as: 'v2_api',    via: ALL_METHODS
  get   '/api/image',    to: 'api#image', as: 'image_api'

  # ===========================================================================
  # Authentication
  # ===========================================================================

  devise_for :users, controllers: {
    sessions:           'user/sessions',
    omniauth_callbacks: 'user/omniauth_callbacks',
  }

  # Synthetic login endpoint.
  devise_scope :user do
    get '/users/sign_in_as', to: 'user/sessions#sign_in_as', as: 'sign_in_as'
  end

  # ===========================================================================
  # Local account operations
  # ===========================================================================

  get    '/account/new_select',    redirect('/account/new'), as: 'new_select_account'     # Only for consistency
  get    '/account/new',           to: 'account#new',        as: 'new_account'
  match  '/account/create',        to: 'account#create',     as: 'create_account',        via: %i[post put patch]

  get    '/account/edit_select',   to: 'account#edit',       as: 'edit_select_account',   defaults: { id: 'SELECT' }
  get    '/account/edit/:id',      to: 'account#edit',       as: 'edit_account'
  match  '/account/update/:id',    to: 'account#update',     as: 'update_account',        via: %i[put patch]

  get    '/account/delete_select', to: 'account#delete',     as: 'delete_select_account', defaults: { id: 'SELECT' }
  get    '/account/delete/:id',    to: 'account#delete',     as: 'delete_account'
  delete '/account/destroy/:id',   to: 'account#destroy',    as: 'destroy_account'

  get    '/account/show/:id',      to: 'account#show',       as: 'show_account'
  get    '/account',               to: 'account#index',      as: 'account_index'

end

# Non-functional hints for RubyMine type checking.
# noinspection RubyInstanceMethodNamingConvention
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
  def home_path(*);                               end
  def home_url(*);                                end
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
  def search_index_path(*);                       end
  def search_index_url(*);                        end
  def session_path(*);                            end
  def session_url(*);                             end
  def sign_in_as_path(*);                         end
  def sign_in_as_url(*);                          end
  def title_index_path(*);                        end
  def title_index_url(*);                         end
  def unlock_path(*);                             end
  def unlock_url(*);                              end
  def upload_index_path(*);                       end
  def upload_index_url(*);                        end
  def user_bookshare_omniauth_authorize_path(*);  end
  def user_bookshare_omniauth_authorize_url(*);   end
  def version_health_path(*);                     end
  def version_health_url(*);                      end
  def welcome_path(*);                            end
  def welcome_url(*);                             end
end
# :nocov:
