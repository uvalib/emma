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

  # noinspection RailsParamDefResolve
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
  get '/search/validate', to: 'search#validate'

  resources :search, only: %i[index show]

  # ===========================================================================
  # File upload operations
  #
  # NOTE: Avoid "resources :upload" because :action can get turned into :id.
  # ===========================================================================

  get    '/upload',                 to: 'upload#index',         as: 'upload_index'
  get    '/upload/show/:id',        to: 'upload#show',          as: 'show_upload'

  # === UploadWorkflow::Single

  get    '/upload/new',             to: 'upload#new',           as: 'new_upload'
  match  '/upload/create',          to: 'upload#create',        as: 'create_upload',          via: %i[post put patch]

  get    '/upload/edit_select',     to: 'upload#edit',          as: 'edit_select_upload',     defaults: { id: 'SELECT' }
  get    '/upload/edit/:id',        to: 'upload#edit',          as: 'edit_upload'
  match  '/upload/update/:id',      to: 'upload#update',        as: 'update_upload',          via: %i[put patch]

  get    '/upload/delete_select',   to: 'upload#delete',        as: 'delete_select_upload',   defaults: { id: 'SELECT' }
  get    '/upload/delete/:id',      to: 'upload#delete',        as: 'delete_upload'
  delete '/upload/destroy/:id',     to: 'upload#destroy',       as: 'destroy_upload'

  # === UploadWorkflow::Bulk

  get    '/upload/bulk_reindex',    to: 'upload#bulk_reindex',  as: 'bulk_reindex_upload'

  get    '/upload/bulk_new',        to: 'upload#bulk_new',      as: 'bulk_new_upload'
  post   '/upload/bulk',            to: 'upload#bulk_create',   as: 'bulk_create_upload'

  get    '/upload/bulk_edit',       to: 'upload#bulk_edit',     as: 'bulk_edit_upload'
  match  '/upload/bulk',            to: 'upload#bulk_update',   as: 'bulk_update_upload',     via: %i[put patch]

  get    '/upload/bulk_delete',     to: 'upload#bulk_delete',   as: 'bulk_delete_upload'
  delete '/upload/bulk',            to: 'upload#bulk_destroy',  as: 'bulk_destroy_upload'

  get    '/upload/bulk',            to: 'upload#bulk_index',    as: 'bulk_upload_index'

  # === UploadWorkflow

  post   '/upload/renew',           to: 'upload#renew',         as: 'renew_upload'
  post   '/upload/reedit',          to: 'upload#reedit',        as: 'reedit_upload'
  match  '/upload/cancel',          to: 'upload#cancel',        as: 'cancel_upload',          via: %i[get post]
  get    '/upload/check/:id',       to: 'upload#check',         as: 'check_upload',           defaults: { modal: true }
  post   '/upload/upload',          to: 'upload#upload',        as: 'upload_upload'           # Invoked from file-upload.js

  # === Administration

  get    '/upload/admin',           to: 'upload#admin',         as: 'admin_upload'

  # === Other

  get    '/upload/api_migrate',     to: 'upload#api_migrate',   as: 'api_migrate'

  # ===========================================================================
  # EMMA entry operations
  #
  # NOTE: Avoid "resources :entry" because :action can get turned into :id.
  # ===========================================================================

  get    '/entry',                  to: 'entry#index',          as: 'entry_index'
  get    '/entry/show/:id',         to: 'entry#show',           as: 'show_entry'

  # === Single-entry workflows

  get    '/entry/new',              to: 'entry#new',            as: 'new_entry'
  match  '/entry/create',           to: 'entry#create',         as: 'create_entry',           via: %i[post put patch]

  get    '/entry/edit_select',      to: 'entry#edit',           as: 'edit_select_entry',      defaults: { id: 'SELECT' }
  get    '/entry/edit/:id',         to: 'entry#edit',           as: 'edit_entry'
  match  '/entry/update/:id',       to: 'entry#update',         as: 'update_entry',           via: %i[put patch]

  get    '/entry/delete_select',    to: 'entry#delete',         as: 'delete_select_entry',    defaults: { id: 'SELECT' }
  get    '/entry/delete/:id',       to: 'entry#delete',         as: 'delete_entry'
  delete '/entry/destroy/:id',      to: 'entry#destroy',        as: 'destroy_entry'

  # === Bulk operation workflows

  get    '/entry/bulk_reindex',     to: 'entry#bulk_reindex',   as: 'bulk_reindex_entry'

  get    '/entry/bulk_new',         to: 'entry#bulk_new',       as: 'bulk_new_entry'
  post   '/entry/bulk',             to: 'entry#bulk_create',    as: 'bulk_create_entry'

  get    '/entry/bulk_edit',        to: 'entry#bulk_edit',      as: 'bulk_edit_entry'
  match  '/entry/bulk',             to: 'entry#bulk_update',    as: 'bulk_update_entry',      via: %i[put patch]

  get    '/entry/bulk_delete',      to: 'entry#bulk_delete',    as: 'bulk_delete_entry'
  delete '/entry/bulk',             to: 'entry#bulk_destroy',   as: 'bulk_destroy_entry'

  get    '/entry/bulk',             to: 'entry#bulk_index',     as: 'bulk_entry_index'

  # === Upload support

  post   '/entry/renew',            to: 'entry#renew',          as: 'renew_entry'
  post   '/entry/reedit',           to: 'entry#reedit',         as: 'reedit_entry'
  match  '/entry/cancel',           to: 'entry#cancel',         as: 'cancel_entry',           via: %i[get post]
  get    '/entry/check/:id',        to: 'entry#check',          as: 'check_entry',            defaults: { modal: true }
  post   '/entry/upload',           to: 'entry#upload',         as: 'entry_upload'            # Invoked from entry.form.js

  # === Administration

  get    '/entry/admin',            to: 'entry#admin',          as: 'admin_entry'
  get    '/entry/phases',           to: 'entry#phases',         as: 'phases'
  get    '/entry/actions',          to: 'entry#actions',        as: 'actions'

  # === Display

  get    '/entry/:id',              to: redirect('/entry/show/%{id}')

  # ===========================================================================
  # File download operations
  # ===========================================================================

  get    '/download/:id',           to: 'upload#download',      as: 'file_download'
  get    '/retrieval',              to: 'upload#retrieval',     as: 'retrieval'

  # ===========================================================================
  # EMMA bulk operations - manifests
  # ===========================================================================

  get    '/manifest/new',           to: 'manifest#new',         as: 'new_manifest'
  match  '/manifest/create',        to: 'manifest#create',      as: 'create_manifest',        via: %i[post put patch]

  get    '/manifest/edit_select',   to: 'manifest#edit',        as: 'edit_select_manifest',   defaults: { id: 'SELECT' }
  get    '/manifest/edit/:id',      to: 'manifest#edit',        as: 'edit_manifest'
  match  '/manifest/update/:id',    to: 'manifest#update',      as: 'update_manifest',        via: %i[put patch]

  get    '/manifest/delete_select', to: 'manifest#delete',      as: 'delete_select_manifest', defaults: { id: 'SELECT' }
  get    '/manifest/delete/:id',    to: 'manifest#delete',      as: 'delete_manifest'
  delete '/manifest/destroy/:id',   to: 'manifest#destroy',     as: 'destroy_manifest'

  match  '/manifest/save/:id',      to: 'manifest#save',        as: 'save_manifest',          via: %i[post put patch]
  match  '/manifest/cancel/:id',    to: 'manifest#cancel',      as: 'cancel_manifest',        via: %i[post put patch]

  get    '/manifest/remit_select',  to: 'manifest#remit',       as: 'remit_select_manifest',  defaults: { id: 'SELECT' }
  get    '/manifest/remit/:id',     to: 'manifest#remit',       as: 'remit_manifest'

  post   '/manifest/start/:id',     to: 'manifest#start',       as: 'start_manifest'
  post   '/manifest/stop/:id',      to: 'manifest#stop',        as: 'stop_manifest'
  post   '/manifest/pause/:id',     to: 'manifest#pause',       as: 'pause_manifest'
  post   '/manifest/resume/:id',    to: 'manifest#resume',      as: 'resume_manifest'

  get    '/manifest/show/:id',      to: 'manifest#show',        as: 'show_manifest'
  get    '/manifest/:id',           to: redirect('/manifest/update/%{id}'),                   via: %i[get post put patch]
  get    '/manifest',               to: 'manifest#index',       as: 'manifest_index'

  # ===========================================================================
  # EMMA bulk operations - manifest items
  # ===========================================================================

  get    '/manifest_item/new/:manifest',          to: 'manifest_item#new',          as: 'new_manifest_item'
  match  '/manifest_item/create/:manifest',       to: 'manifest_item#create',       as: 'create_manifest_item',       via: %i[post put patch]

  get    '/manifest_item/edit/:manifest/:id',     to: 'manifest_item#edit',         as: 'edit_manifest_item'
  match  '/manifest_item/update/:manifest/:id',   to: 'manifest_item#update',       as: 'update_manifest_item',       via: %i[put patch]

  get    '/manifest_item/delete/:manifest/:id',   to: 'manifest_item#delete',       as: 'delete_manifest_item'
  delete '/manifest_item/destroy/:manifest/:id',  to: 'manifest_item#destroy',      as: 'destroy_manifest_item'

  post   '/manifest_item/start_edit/:id',         to: 'manifest_item#start_edit'
  post   '/manifest_item/finish_edit/:id',        to: 'manifest_item#finish_edit'
  post   '/manifest_item/row_update/:id',         to: 'manifest_item#row_update'
  post   '/manifest_item/upload',                 to: 'manifest_item#upload',       as: 'manifest_item_upload'        # Invoked from file-upload.js

  get    '/manifest_item/bulk/new/:manifest',     to: 'manifest_item#bulk_new',     as: 'bulk_new_manifest_item'
  match  '/manifest_item/bulk/create/:manifest',  to: 'manifest_item#bulk_create',  as: 'bulk_create_manifest_item',  via: %i[post put patch]

  get    '/manifest_item/bulk/edit/:manifest',    to: 'manifest_item#bulk_edit',    as: 'bulk_edit_manifest_item'
  match  '/manifest_item/bulk/update/:manifest',  to: 'manifest_item#bulk_update',  as: 'bulk_update_manifest_item',  via: %i[put patch]

  get    '/manifest_item/bulk/delete/:manifest',  to: 'manifest_item#bulk_delete',  as: 'bulk_delete_manifest_item'
  delete '/manifest_item/bulk/destroy/:manifest', to: 'manifest_item#bulk_destroy', as: 'bulk_destroy_manifest_item'

  get    '/manifest_item/show/:manifest/:id',     to: 'manifest_item#show',         as: 'show_manifest_item'
  get    '/manifest_item/:manifest',              to: 'manifest_item#index',        as: 'manifest_item_index'

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

  get '/edition/:editionId/:fmt?seriesId=:seriesId', to: 'edition#download', as: 'edition_download'

  # ===========================================================================
  # Artifact operations
  # ===========================================================================

  get '/artifact/retrieval',          to: 'artifact#retrieval', as: 'bs_retrieval'
  get '/artifact/:bookshareId/:fmt',  to: 'artifact#download',  as: 'bs_download'

  resources :artifact, except: %i[index create]

  post  '/artifact/create',     to: 'artifact#create', as: 'create_artifact'
  match '/artifact/update/:id', to: 'artifact#update', as: 'update_artifact', via: %i[put patch]

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

  # noinspection RailsParamDefResolve
  resource :health, controller: 'health', only: [] do
    get :version
    get :check
    get 'check/:subsystem',   to: 'health#check',         as: 'check_subsystem'
    get :run_state,           to: 'health#run_state',     as: 'run_state'
    put :run_state,           to: 'health#set_run_state', as: 'set_run_state'
  end

  get '/version',             to: 'health#version'
  get '/healthcheck',         to: 'health#check'
  get '/system_unavailable',  to: 'health#run_state'

  # ===========================================================================
  # Metrics
  #
  # NOTE: "GET /metrics" is handled by Prometheus::Middleware::Exporter
  # ===========================================================================

  get '/metrics/test', to: 'metrics#test'

  # ===========================================================================
  # API test routes
  # ===========================================================================

  resources :bs_api, only: %i[index]

  match '/bs_api/v2/*api_path', to: 'bs_api#v2',    as: 'bs_api_v2',    via: ALL_METHODS
  get   '/bs_api/image',        to: 'bs_api#image', as: 'bs_api_image'

  # ===========================================================================
  # Authentication
  # ===========================================================================

  get '/users', to: 'account#index'

  devise_for :users, controllers: {
    sessions:           'user/sessions',
    passwords:          'user/passwords',
    registrations:      'user/registrations',
    omniauth_callbacks: 'user/omniauth_callbacks',
  }

  # Local login.
  devise_scope :user do
    get '/users/sign_in_local', to: 'user/sessions#sign_in_local',    as: 'sign_in_local'
  end

  # Synthetic login endpoint.
  devise_scope :user do
    get '/users/sign_in_as',    to: 'user/sessions#sign_in_as',       as: 'sign_in_as'
  end

  devise_scope :user do
    get   '/users/new',         to: 'user/registrations#new',         as: 'new_user'
    match '/users/create',      to: 'user/registrations#create',      as: 'create_user',        via: %i[post put patch]
    get   '/users/edit_select', to: 'user/registrations#edit_select', as: 'edit_select_user',   defaults: { id: 'SELECT' }
    get   '/users/edit/:id',    to: 'user/registrations#edit',        as: 'edit_user'
    match '/users/update/:id',  to: 'user/registrations#update',      as: 'update_user',        via: %i[post put patch]
  end

  # ===========================================================================
  # Local account operations
  # ===========================================================================

  resources :account, only: %i[index]

  get    '/account/show/:id',       to: 'account#show',           as: 'show_account'

  get    '/account/new',            to: 'account#new',            as: 'new_account'
  match  '/account/create',         to: 'account#create',         as: 'create_account',         via: %i[post put patch]

  get    '/account/edit_select',    to: 'account#edit',           as: 'edit_select_account',    defaults: { id: 'SELECT' }
  # noinspection RailsParamDefResolve
  get    '/account/edit/:id',       to: 'account#edit',           as: 'edit_account',           defaults: { id: try(:current_user)&.id }
  match  '/account/update/:id',     to: 'account#update',         as: 'update_account',         via: %i[put patch]

  get    '/account/delete_select',  to: 'account#delete',         as: 'delete_select_account',  defaults: { id: 'SELECT' }
  get    '/account/delete/:id',     to: 'account#delete',         as: 'delete_account'
  delete '/account/destroy/:id',    to: 'account#destroy',        as: 'destroy_account'

  # ===========================================================================
  # Search call viewer
  # ===========================================================================

  resources :search_call, only: %i[index show]

  # ===========================================================================
  # Administration
  # ===========================================================================

  match '/admin', to: 'admin#update', as: 'update_admin', via: %i[post put patch]

  AdminController::PAGES.each do |page|
    get "/admin/#{page}", to: "admin##{page}", as: "#{page}_admin"
  end

  resources :admin, only: %i[index]

  # ===========================================================================
  # Database viewer
  # ===========================================================================

  get '/data/submissions', to: 'data#submissions'
  get '/data/counts',      to: 'data#counts'
  get '/data',             to: 'data#index', as: 'data_index'

  resource :data, only: %i[show]

  # ===========================================================================
  # Job scheduler
  # ===========================================================================

  # GoodJob dashboard
  authenticate :user, ->(user) { Ability.new(user).can?(:manage, GoodJob) } do
    mount GoodJob::Engine => 'good_job'
  end

  # ===========================================================================
  # Utilities and tools pages
  # ===========================================================================

  resources :tool, only: %i[index]

  get   '/tool/md',       to: 'tool#md',       as: 'md_trial'
  match '/tool/md_proxy', to: 'tool#md_proxy', as: 'md_proxy', via: %i[get post]
  get   '/tool/lookup',   to: 'tool#lookup',   as: 'bib_lookup'

  get   '/tool/lookup_result/:job_id',       to: 'tool#lookup_result', as: 'bib_lookup_result'
  get   '/tool/lookup_result/:job_id/*path', to: 'tool#lookup_result', as: 'bib_lookup_result_path'

end

# Non-functional hints for RubyMine type checking.
# noinspection RubyInstanceMethodNamingConvention
unless ONLY_FOR_DOCUMENTATION
  # :nocov:
  def account_index_path(...);                     end
  def account_index_url(...);                      end
  def admin_entry_path(...);                       end
  def admin_entry_url(...);                        end
  def admin_upload_path(...);                      end
  def admin_upload_url(...);                       end
  def advanced_search_path(...);                   end
  def advanced_search_url(...);                    end
  def api_migrate_path(...);                       end
  def api_migrate_url(...);                        end
  def artifact_index_path(...);                    end
  def artifact_index_url(...);                     end
  def artifact_path(...);                          end
  def artifact_url(...);                           end
  def bs_api_index_path(...);                      end
  def bs_api_index_url(...);                       end
  def bs_download_path(...);                       end
  def bs_download_url(...);                        end
  def bs_retrieval_path(...);                      end
  def bs_retrieval_url(...);                       end
  def bulk_create_entry_path(...);                 end
  def bulk_create_entry_url(...);                  end
  def bulk_create_manifest_item_path(...);         end
  def bulk_create_manifest_item_url(...);          end
  def bulk_create_upload_path(...);                end
  def bulk_create_upload_url(...);                 end
  def bulk_delete_entry_path(...);                 end
  def bulk_delete_entry_url(...);                  end
  def bulk_delete_manifest_item_path(...);         end
  def bulk_delete_manifest_item_url(...);          end
  def bulk_delete_upload_path(...);                end
  def bulk_delete_upload_url(...);                 end
  def bulk_destroy_entry_path(...);                end
  def bulk_destroy_entry_url(...);                 end
  def bulk_destroy_manifest_item_path(...);        end
  def bulk_destroy_manifest_item_url(...);         end
  def bulk_destroy_upload_path(...);               end
  def bulk_destroy_upload_url(...);                end
  def bulk_edit_entry_path(...);                   end
  def bulk_edit_entry_url(...);                    end
  def bulk_edit_manifest_item_path(...);           end
  def bulk_edit_manifest_item_url(...);            end
  def bulk_edit_upload_path(...);                  end
  def bulk_edit_upload_url(...);                   end
  def bulk_entry_index_path(...);                  end
  def bulk_entry_index_url(...);                   end
  def bulk_new_entry_path(...);                    end
  def bulk_new_entry_url(...);                     end
  def bulk_new_manifest_item_path(...);            end
  def bulk_new_manifest_item_url(...);             end
  def bulk_new_upload_path(...);                   end
  def bulk_new_upload_url(...);                    end
  def bulk_reindex_entry_path(...);                end
  def bulk_reindex_entry_url(...);                 end
  def bulk_reindex_upload_path(...);               end
  def bulk_reindex_upload_url(...);                end
  def bulk_update_entry_path(...);                 end
  def bulk_update_entry_url(...);                  end
  def bulk_update_manifest_item_path(...);         end
  def bulk_update_manifest_item_url(...);          end
  def bulk_update_upload_path(...);                end
  def bulk_update_upload_url(...);                 end
  def bulk_upload_index_path(...);                 end
  def bulk_upload_index_url(...);                  end
  def cancel_entry_path(...);                      end
  def cancel_entry_url(...);                       end
  def cancel_manifest_path(...);                   end
  def cancel_manifest_url(...);                    end
  def cancel_upload_path(...);                     end
  def cancel_upload_url(...);                      end
  def cancel_user_registration_path(...);          end
  def cancel_user_registration_url(...);           end
  def category_index_path(...);                    end
  def category_index_url(...);                     end
  def check_entry_path(...);                       end
  def check_entry_url(...);                        end
  def check_health_path(...);                      end
  def check_health_url(...);                       end
  def check_subsystem_health_path(...);            end
  def check_subsystem_health_url(...);             end
  def check_upload_path(...);                      end
  def check_upload_url(...);                       end
  def confirmation_path(...);                      end
  def confirmation_url(...);                       end
  def create_account_path(...);                    end
  def create_account_url(...);                     end
  def create_artifact_path(...);                   end
  def create_artifact_url(...);                    end
  def create_entry_path(...);                      end
  def create_entry_url(...);                       end
  def create_manifest_item_path(...);              end
  def create_manifest_item_url(...);               end
  def create_manifest_path(...);                   end
  def create_manifest_url(...);                    end
  def create_upload_path(...);                     end
  def create_upload_url(...);                      end
  def create_user_path(...);                       end
  def create_user_registration_path(...);          end
  def create_user_registration_url(...);           end
  def create_user_url(...);                        end
  def dashboard_path(...);                         end
  def dashboard_url(...);                          end
  def data_counts_path(...);                       end
  def data_counts_url(...);                        end
  def data_index_path(...);                        end
  def data_index_url(...);                         end
  def data_path(...);                              end
  def data_submissions_path(...);                  end
  def data_submissions_url(...);                   end
  def data_url(...);                               end
  def delete_account_path(...);                    end
  def delete_account_url(...);                     end
  def delete_entry_path(...);                      end
  def delete_entry_url(...);                       end
  def delete_manifest_item_path(...);              end
  def delete_manifest_item_url(...);               end
  def delete_manifest_path(...);                   end
  def delete_manifest_url(...);                    end
  def delete_select_account_path(...);             end
  def delete_select_account_url(...);              end
  def delete_select_entry_path(...);               end
  def delete_select_entry_url(...);                end
  def delete_select_manifest_path(...);            end
  def delete_select_manifest_url(...);             end
  def delete_select_upload_path(...);              end
  def delete_select_upload_url(...);               end
  def delete_select_user_registration_path(...);   end
  def delete_select_user_registration_url(...);    end
  def delete_upload_path(...);                     end
  def delete_upload_url(...);                      end
  def delete_user_registration_path(...);          end
  def delete_user_registration_url(...);           end
  def destroy_account_path(...);                   end
  def destroy_account_url(...);                    end
  def destroy_entry_path(...);                     end
  def destroy_entry_url(...);                      end
  def destroy_manifest_item_path(...);             end
  def destroy_manifest_item_url(...);              end
  def destroy_manifest_path(...);                  end
  def destroy_manifest_url(...);                   end
  def destroy_upload_path(...);                    end
  def destroy_upload_url(...);                     end
  def destroy_user_registration_path(...);         end
  def destroy_user_registration_url(...);          end
  def destroy_user_session_path(...);              end
  def destroy_user_session_url(...);               end
  def edit_account_path(...);                      end
  def edit_account_url(...);                       end
  def edit_artifact_path(...);                     end
  def edit_artifact_url(...);                      end
  def edit_edition_path(...);                      end
  def edit_edition_url(...);                       end
  def edit_entry_path(...);                        end
  def edit_entry_url(...);                         end
  def edit_manifest_item_path(...);                end
  def edit_manifest_item_url(...);                 end
  def edit_manifest_path(...);                     end
  def edit_manifest_url(...);                      end
  def edit_member_path(...);                       end
  def edit_member_url(...);                        end
  def edit_password_path(...);                     end
  def edit_password_url(...);                      end
  def edit_periodical_path(...);                   end
  def edit_periodical_url(...);                    end
  def edit_select_account_path(...);               end
  def edit_select_account_url(...);                end
  def edit_select_entry_path(...);                 end
  def edit_select_entry_url(...);                  end
  def edit_select_manifest_path(...);              end
  def edit_select_manifest_url(...);               end
  def edit_select_upload_path(...);                end
  def edit_select_upload_url(...);                 end
  def edit_select_user_path(...);                  end # /users/edit_select
  def edit_select_user_registration_path(...);     end
  def edit_select_user_registration_url(...);      end
  def edit_select_user_url(...);                   end
  def edit_title_path(...);                        end
  def edit_title_url(...);                         end
  def edit_upload_path(...);                       end
  def edit_upload_url(...);                        end
  def edit_user_path(...);                         end
  def edit_user_registration_path(...);            end # /users/edit
  def edit_user_registration_url(...);             end
  def edit_user_url(...);                          end
  def edition_download_path(...);                  end
  def edition_download_url(...);                   end
  def edition_index_path(...);                     end
  def edition_index_url(...);                      end
  def entry_index_path(...);                       end
  def entry_index_url(...);                        end
  def entry_upload_path(...);                      end
  def entry_upload_url(...);                       end
  def file_download_path(...);                     end
  def file_download_url(...);                      end
  def healthcheck_path(...);                       end
  def healthcheck_url(...);                        end
  def help_index_path(...);                        end
  def help_index_url(...);                         end
  def help_path(...);                              end
  def help_url(...);                               end
  def history_title_path(...);                     end
  def history_title_url(...);                      end
  def home_path(...);                              end
  def home_url(...);                               end
  def manifest_index_path(...);                    end
  def manifest_index_url(...);                     end
  def manifest_item_index_path(...);               end
  def manifest_item_index_url(...);                end
  def manifest_item_upload_path(...);              end
  def manifest_item_upload_url(...);               end
  def md_proxy_path(...);                          end
  def md_proxy_url(...);                           end
  def md_trial_path(...);                          end
  def md_trial_url(...);                           end
  def member_index_path(...);                      end
  def member_index_url(...);                       end
  def member_path(...);                            end
  def member_url(...);                             end
  def metrics_test_path(...);                      end
  def metrics_test_url(...);                       end
  def new_account_path(...);                       end
  def new_account_url(...);                        end
  def new_artifact_path(...);                      end
  def new_artifact_url(...);                       end
  def new_edition_path(...);                       end
  def new_edition_url(...);                        end
  def new_entry_path(...);                         end
  def new_entry_url(...);                          end
  def new_manifest_item_path(...);                 end
  def new_manifest_item_url(...);                  end
  def new_manifest_path(...);                      end
  def new_manifest_url(...);                       end
  def new_member_path(...);                        end
  def new_member_url(...);                         end
  def new_periodical_path(...);                    end
  def new_periodical_url(...);                     end
  def new_title_path(...);                         end
  def new_title_url(...);                          end
  def new_upload_path(...);                        end
  def new_upload_url(...);                         end
  def new_user_path(...);                          end
  def new_user_registration_path(...);             end # /users/new
  def new_user_registration_url(...);              end
  def new_user_session_path(...);                  end
  def new_user_session_url(...);                   end
  def new_user_url(...);                           end
  def password_path(...);                          end
  def password_url(...);                           end
  def periodical_index_path(...);                  end
  def periodical_index_url(...);                   end
  def reading_list_index_path(...);                end
  def reading_list_index_url(...);                 end
  def reedit_entry_path(...);                      end
  def reedit_entry_url(...);                       end
  def reedit_upload_path(...);                     end
  def reedit_upload_url(...);                      end
  def registration_path(...);                      end
  def registration_url(...);                       end
  def renew_entry_path(...);                       end
  def renew_entry_url(...);                        end
  def renew_upload_path(...);                      end
  def renew_upload_url(...);                       end
  def retrieval_path(...);                         end
  def retrieval_url(...);                          end
  def root_path(...);                              end
  def root_url(...);                               end
  def run_state_health_path(...);                  end
  def run_state_health_url(...);                   end
  def save_manifest_path(...);                     end
  def save_manifest_url(...);                      end
  def search_api_path(...);                        end
  def search_api_url(...);                         end
  def search_call_index_path(...);                 end
  def search_call_index_url(...);                  end
  def search_call_path(...);                       end
  def search_call_url(...);                        end
  def search_direct_path(...);                     end
  def search_direct_url(...);                      end
  def search_index_path(...);                      end
  def search_index_url(...);                       end
  def search_path(...);                            end
  def search_url(...);                             end
  def search_validate_path(...);                   end
  def search_validate_url(...);                    end
  def session_path(...);                           end
  def session_url(...);                            end
  def set_run_state_health_path(...);              end
  def set_run_state_health_url(...);               end
  def show_account_path(...);                      end
  def show_account_url(...);                       end
  def show_entry_path(...);                        end
  def show_entry_url(...);                         end
  def show_manifest_item_path(...);                end
  def show_manifest_item_url(...);                 end
  def show_manifest_path(...);                     end
  def show_manifest_url(...);                      end
  def show_upload_path(...);                       end
  def show_upload_url(...);                        end
  def show_user_registration_path(...);            end
  def show_user_registration_url(...);             end
  def sign_in_as_path(...);                        end # /users/sign_in_as
  def sign_in_as_url(...);                         end
  def sign_in_local_path(...);                     end # /users/sign_in_local
  def sign_in_local_url(...);                      end
  def system_unavailable_path(...);                end
  def system_unavailable_url(...);                 end
  def title_index_path(...);                       end
  def title_index_url(...);                        end
  def title_path(...);                             end
  def title_url(...);                              end
  def tool_index_path(...);                        end
  def tool_index_url(...);                         end
  def unlock_path(...);                            end
  def unlock_url(...);                             end
  def update_account_path(...);                    end
  def update_account_url(...);                     end
  def update_artifact_path(...);                   end
  def update_artifact_url(...);                    end
  def update_entry_path(...);                      end
  def update_entry_url(...);                       end
  def update_manifest_item_path(...);              end
  def update_manifest_item_url(...);               end
  def update_manifest_path(...);                   end
  def update_manifest_url(...);                    end
  def update_upload_path(...);                     end
  def update_upload_url(...);                      end
  def update_user_path(...);                       end
  def update_user_url(...);                        end
  def upload_index_path(...);                      end
  def upload_index_url(...);                       end
  def upload_upload_path(...);                     end
  def upload_upload_url(...);                      end
  def user_bookshare_omniauth_authorize_path(...); end
  def user_bookshare_omniauth_authorize_url(...);  end
  def user_registration_path(...);                 end
  def user_registration_url(...);                  end
  def version_health_path(...);                    end
  def version_health_url(...);                     end
  def version_path(...);                           end
  def version_url(...);                            end
  def welcome_path(...);                           end
  def welcome_url(...);                            end
  # :nocov:
end
