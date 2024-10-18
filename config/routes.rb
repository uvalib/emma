# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true

# noinspection LongLine
Rails.application.routes.draw do

  CURRENT    ||= ParamsHelper::CURRENT_ID
  VIA_ANY    ||= { via: %i[put patch post get] }.deep_freeze
  VIA_CREATE ||= { via: %i[put patch post] }.deep_freeze
  VIA_UPDATE ||= { via: %i[put patch] }.deep_freeze

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

  get    '/upload',                 to: 'upload#index',           as: 'upload_index'
  get    '/upload/index',           to: 'upload#index'
  get    '/upload/list_all',        to: 'upload#list_all',        as: 'list_all_upload'
  get    '/upload/list_org',        to: 'upload#list_org',        as: 'list_org_upload'
  get    '/upload/list_own',        to: 'upload#list_own',        as: 'list_own_upload'

  get    '/upload/show_select',     to: 'upload#show_select',     as: 'show_select_upload'
  get    '/upload/show/(:id)',      to: 'upload#show',            as: 'show_upload'

  # === UploadWorkflow::Single

  get    '/upload/new',             to: 'upload#new',             as: 'new_upload'
  match  '/upload/create',          to: 'upload#create',          as: 'create_upload',        **VIA_CREATE

  get    '/upload/edit_select',     to: 'upload#edit_select',     as: 'edit_select_upload'
  get    '/upload/edit/(:id)',      to: 'upload#edit',            as: 'edit_upload'
  match  '/upload/update/:id',      to: 'upload#update',          as: 'update_upload',        **VIA_UPDATE

  get    '/upload/delete_select',   to: 'upload#delete_select',   as: 'delete_select_upload'
  get    '/upload/delete/(:id)',    to: 'upload#delete',          as: 'delete_upload'
  delete '/upload/destroy/:id',     to: 'upload#destroy',         as: 'destroy_upload'

  # === UploadWorkflow::Bulk

  get    '/upload/bulk_reindex',    to: 'upload#bulk_reindex',    as: 'bulk_reindex_upload'

  get    '/upload/bulk_new',        to: 'upload#bulk_new',        as: 'bulk_new_upload'
  post   '/upload/bulk',            to: 'upload#bulk_create',     as: 'bulk_create_upload'

  get    '/upload/bulk_edit',       to: 'upload#bulk_edit',       as: 'bulk_edit_upload'
  match  '/upload/bulk',            to: 'upload#bulk_update',     as: 'bulk_update_upload',   **VIA_UPDATE

  get    '/upload/bulk_delete',     to: 'upload#bulk_delete',     as: 'bulk_delete_upload'
  delete '/upload/bulk',            to: 'upload#bulk_destroy',    as: 'bulk_destroy_upload'

  get    '/upload/bulk',            to: 'upload#bulk_index',      as: 'bulk_upload_index'

  # === UploadWorkflow

  post   '/upload/renew',           to: 'upload#renew',           as: 'renew_upload'
  post   '/upload/reedit',          to: 'upload#reedit',          as: 'reedit_upload'
  match  '/upload/cancel',          to: 'upload#cancel',          as: 'cancel_upload',        **VIA_ANY
  get    '/upload/check/:id',       to: 'upload#check',           as: 'check_upload',         defaults: { modal: true }
  post   '/upload/upload',          to: 'upload#upload',          as: 'upload_upload'         # Invoked from file-upload.js

  # === Administration

  get    '/upload/admin',           to: 'upload#admin',           as: 'admin_upload'
  get    '/upload/records',         to: 'upload#records'

  # === Other

  get    '/upload/api_migrate',     to: 'upload#api_migrate',     as: 'api_migrate'

  # ===========================================================================
  # File download operations
  # ===========================================================================

  get    '/download/:id',           to: 'upload#download',        as: 'file_download'
  get    '/retrieval',              to: 'upload#retrieval',       as: 'retrieval'
  get    '/probe_retrieval',        to: 'upload#probe_retrieval', as: 'probe_retrieval'

  # ===========================================================================
  # EMMA bulk operations - manifests
  # ===========================================================================

  get    '/manifest',               to: 'manifest#index',         as: 'manifest_index'
  get    '/manifest/index',         to: 'manifest#index'
  get    '/manifest/list_all',      to: 'manifest#list_all',      as: 'list_all_manifest'
  get    '/manifest/list_org',      to: 'manifest#list_org',      as: 'list_org_manifest'
  get    '/manifest/list_own',      to: 'manifest#list_own',      as: 'list_own_manifest'

  get    '/manifest/new',           to: 'manifest#new',           as: 'new_manifest'
  match  '/manifest/create',        to: 'manifest#create',        as: 'create_manifest',        **VIA_CREATE

  get    '/manifest/edit_select',   to: 'manifest#edit_select',   as: 'edit_select_manifest'
  get    '/manifest/edit/(:id)',    to: 'manifest#edit',          as: 'edit_manifest'
  match  '/manifest/update/:id',    to: 'manifest#update',        as: 'update_manifest',        **VIA_UPDATE

  get    '/manifest/delete_select', to: 'manifest#delete_select', as: 'delete_select_manifest'
  get    '/manifest/delete/(:id)',  to: 'manifest#delete',        as: 'delete_manifest'
  delete '/manifest/destroy/:id',   to: 'manifest#destroy',       as: 'destroy_manifest'

  match  '/manifest/save/:id',      to: 'manifest#save',          as: 'save_manifest',          **VIA_CREATE
  match  '/manifest/cancel/:id',    to: 'manifest#cancel',        as: 'cancel_manifest',        **VIA_CREATE

  get    '/manifest/remit_select',  to: 'manifest#remit_select',  as: 'remit_select_manifest'
  get    '/manifest/remit/(:id)',   to: 'manifest#remit',         as: 'remit_manifest'

  get    '/manifest/get_job_result/:job_id',       to: 'manifest#get_job_result'
  get    '/manifest/get_job_result/:job_id/*path', to: 'manifest#get_job_result'

=begin # TODO: submission start/stop ?
  post   '/manifest/start/:id',     to: 'manifest#start',         as: 'start_manifest'
  post   '/manifest/stop/:id',      to: 'manifest#stop',          as: 'stop_manifest'
  post   '/manifest/pause/:id',     to: 'manifest#pause',         as: 'pause_manifest'
  post   '/manifest/resume/:id',    to: 'manifest#resume',        as: 'resume_manifest'
=end

  get    '/manifest/show_select',   to: 'manifest#show_select',   as: 'show_select_manifest'
  get    '/manifest/show/(:id)',    to: 'manifest#show',          as: 'show_manifest'
  get    '/manifest/:id',           to: redirect('/manifest/edit/%{id}')

  # ===========================================================================
  # EMMA bulk operations - manifest items
  # ===========================================================================

  get    '/manifest_item/new/:manifest',          to: 'manifest_item#new',          as: 'new_manifest_item'
  match  '/manifest_item/create/:manifest',       to: 'manifest_item#create',       as: 'create_manifest_item',       **VIA_CREATE

  get    '/manifest_item/edit/:manifest/:id',     to: 'manifest_item#edit',         as: 'edit_manifest_item'
  match  '/manifest_item/update/:manifest/:id',   to: 'manifest_item#update',       as: 'update_manifest_item',       **VIA_UPDATE

  get    '/manifest_item/delete/:manifest/:id',   to: 'manifest_item#delete',       as: 'delete_manifest_item'
  delete '/manifest_item/destroy/:manifest/:id',  to: 'manifest_item#destroy',      as: 'destroy_manifest_item'

  post   '/manifest_item/start_edit/:id',         to: 'manifest_item#start_edit'
  post   '/manifest_item/finish_edit/:id',        to: 'manifest_item#finish_edit'
  post   '/manifest_item/row_update/:id',         to: 'manifest_item#row_update'
  post   '/manifest_item/upload',                 to: 'manifest_item#upload',       as: 'manifest_item_upload'        # Invoked from file-upload.js

  get    '/manifest_item/bulk/new/:manifest',     to: 'manifest_item#bulk_new',     as: 'bulk_new_manifest_item'
  match  '/manifest_item/bulk/create/:manifest',  to: 'manifest_item#bulk_create',  as: 'bulk_create_manifest_item',  **VIA_CREATE

  get    '/manifest_item/bulk/edit/:manifest',    to: 'manifest_item#bulk_edit',    as: 'bulk_edit_manifest_item'
  match  '/manifest_item/bulk/update/:manifest',  to: 'manifest_item#bulk_update',  as: 'bulk_update_manifest_item',  **VIA_UPDATE
  match  '/manifest_item/bulk/fields/:manifest',  to: 'manifest_item#bulk_fields',  as: 'bulk_fields_manifest_item',  **VIA_UPDATE

  get    '/manifest_item/bulk/delete/:manifest',  to: 'manifest_item#bulk_delete',  as: 'bulk_delete_manifest_item'
  delete '/manifest_item/bulk/destroy/:manifest', to: 'manifest_item#bulk_destroy', as: 'bulk_destroy_manifest_item'

  get    '/manifest_item/show/:manifest/:id',     to: 'manifest_item#show'
  get    '/manifest_item/:manifest/:id',          to: 'manifest_item#show',         as: 'show_manifest_item'
  get    '/manifest_item/:manifest',              to: 'manifest_item#index',        as: 'manifest_item_index'

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
    get '/users/sign_in_as',    to: 'user/sessions#sign_in_as',       as: 'sign_in_as'        if SIGN_IN_AS
  end

  devise_scope :user do
    get   '/users/new',         to: 'user/registrations#new',         as: 'new_user'
    match '/users/create',      to: 'user/registrations#create',      as: 'create_user',      **VIA_CREATE
    get   '/users/edit_select', to: 'user/registrations#edit_select', as: 'edit_select_user'
    get   '/users/edit/:id',    to: 'user/registrations#edit',        as: 'edit_user'
    match '/users/update/:id',  to: 'user/registrations#update',      as: 'update_user',      **VIA_CREATE
  end

  # ===========================================================================
  # Local account operations
  # ===========================================================================

  resources :account, only: %i[index]

  get    '/account/index',            to: 'account#index'
  get    '/account/list_all',         to: 'account#list_all',         as: 'list_all_account'
  get    '/account/list_org',         to: 'account#list_org',         as: 'list_org_account'

  get    '/account/show_current',     to: 'account#show_current',     as: 'show_current_account'
  get    '/account/show_select',      to: 'account#show_select',      as: 'show_select_account'
  get    '/account/show/(:id)',       to: 'account#show',             as: 'show_account'

  get    '/account/new',              to: 'account#new',              as: 'new_account'
  match  '/account/create',           to: 'account#create',           as: 'create_account',       **VIA_CREATE

  get    '/account/edit_current',     to: 'account#edit_current',     as: 'edit_current_account'
  get    '/account/edit_select',      to: 'account#edit_select',      as: 'edit_select_account'
  get    '/account/edit/(:id)',       to: 'account#edit',             as: 'edit_account'
  match  '/account/update/:id',       to: 'account#update',           as: 'update_account',       **VIA_UPDATE

  get    '/account/delete_select',    to: 'account#delete_select',    as: 'delete_select_account'
  get    '/account/delete/(:id)',     to: 'account#delete',           as: 'delete_account'
  delete '/account/destroy/:id',      to: 'account#destroy',          as: 'destroy_account'

  # ===========================================================================
  # Organizations
  # ===========================================================================

  resources :org, only: %i[index]

  get    '/org/index',                to: 'org#index'
  get    '/org/list_all',             to: 'org#list_all',             as: 'list_all_org'

  get    '/org/show_current',         to: 'org#show_current',         as: 'show_current_org'
  get    '/org/show_select',          to: 'org#show_select',          as: 'show_select_org'
  get    '/org/show/(:id)',           to: 'org#show',                 as: 'show_org'

  get    '/org/new',                  to: 'org#new',                  as: 'new_org'
  match  '/org/create',               to: 'org#create',               as: 'create_org',           **VIA_CREATE

  get    '/org/edit_current',         to: 'org#edit_current',         as: 'edit_current_org'
  get    '/org/edit_select',          to: 'org#edit_select',          as: 'edit_select_org'
  get    '/org/edit/(:id)',           to: 'org#edit',                 as: 'edit_org'
  match  '/org/update/:id',           to: 'org#update',               as: 'update_org',           **VIA_UPDATE

  get    '/org/delete_select',        to: 'org#delete_select',        as: 'delete_select_org'
  get    '/org/delete/(:id)',         to: 'org#delete',               as: 'delete_org'
  delete '/org/destroy/:id',          to: 'org#destroy',              as: 'destroy_org'

  get    '/org/:id',                  to: 'org#edit', defaults: { id: CURRENT }

  # ===========================================================================
  # EMMA membership enrollment
  # ===========================================================================

  resources :enrollment, only: %i[index]

  get    '/enrollment/index',         to: 'enrollment#index'

  get    '/enrollment/show_select',   to: 'enrollment#show_select',   as: 'show_select_enrollment'
  get    '/enrollment/show/(:id)',    to: 'enrollment#show',          as: 'show_enrollment'

  get    '/enrollment/new',           to: 'enrollment#new',           as: 'new_enrollment'
  match  '/enrollment/create',        to: 'enrollment#create',        as: 'create_enrollment', **VIA_CREATE

  get    '/enrollment/edit_select',   to: 'enrollment#edit_select',   as: 'edit_select_enrollment'
  get    '/enrollment/edit/(:id)',    to: 'enrollment#edit',          as: 'edit_enrollment'
  match  '/enrollment/update/:id',    to: 'enrollment#update',        as: 'update_enrollment', **VIA_UPDATE

  get    '/enrollment/delete_select', to: 'enrollment#delete_select', as: 'delete_select_enrollment'
  get    '/enrollment/delete/(:id)',  to: 'enrollment#delete',        as: 'delete_enrollment'
  delete '/enrollment/destroy/:id',   to: 'enrollment#destroy',       as: 'destroy_enrollment'

  post   '/enrollment/finalize',      to: 'enrollment#finalize',      as: 'finalize_enrollment'
  get    '/enroll',                   to: redirect('/enrollment/new')

  # ===========================================================================
  # Search call viewer
  # ===========================================================================

  resources :search_call, only: %i[index show]

  # ===========================================================================
  # Application information
  # ===========================================================================

  get '/about',             to: 'about#index',    as: 'about_index'

  AboutController::PAGES.excluding(:index).each do |page|
    get "/about/#{page}",   to: "about##{page}",  as: "#{page}_about"
  end

  # ===========================================================================
  # System information
  # ===========================================================================

  get   '/sys',             to: 'sys#index',    as: 'sys_index'
  match '/sys',             to: 'sys#update',   as: 'update_sys', **VIA_CREATE
  get   '/sys/view',        to: 'sys#view'

  SysController::PAGES.excluding(:index).each do |page|
    get "/sys/#{page}",     to: "sys##{page}",  as: "#{page}_sys"
  end

  # ===========================================================================
  # Database viewer
  # ===========================================================================

  get '/data/submissions',  to: 'data#submissions'
  get '/data/counts',       to: 'data#counts'
  get '/data/show',         to: 'data#show',    as: 'data'
  get '/data/:id',          to: 'data#show'
  get '/data',              to: 'data#index',   as: 'data_index'

  # ===========================================================================
  # Job scheduler
  # ===========================================================================

  # GoodJob dashboard
  if not_deployed?
    mount GoodJob::Engine => 'good_job'
  else
    authenticate :user, ->(user) { user&.can?(:manage, GoodJob) } do
      mount GoodJob::Engine => 'good_job'
    end
  end

  # ===========================================================================
  # Utilities and tools pages
  # ===========================================================================

  resources :tool, only: %i[index]

  get   '/tool/md',         to: 'tool#md',        as: 'md_trial'
  match '/tool/md_proxy',   to: 'tool#md_proxy',  as: 'md_proxy', **VIA_ANY
  get   '/tool/lookup',     to: 'tool#lookup',    as: 'bib_lookup'

  get   '/tool/get_job_result/:job_id',       to: 'tool#get_job_result'
  get   '/tool/get_job_result/:job_id/*path', to: 'tool#get_job_result'

  # ===========================================================================
  # Old routes that still get hit by robots
  # ===========================================================================

  get '/artifact(/*any)',   to: 'application#return_to_sender'
  get '/bs_api(/*any)',     to: 'application#return_to_sender'
  get '/periodical(/*any)', to: 'application#return_to_sender'
  get '/title(/*any)',      to: 'application#return_to_sender'
  get '/v2(/*any)',         to: 'application#return_to_sender'

end

# Non-functional hints for RubyMine type checking.
# :nocov:
# noinspection RubyInstanceMethodNamingConvention
unless ONLY_FOR_DOCUMENTATION
  def account_index_path(...);                     end
  def account_index_url(...);                      end
  def admin_upload_path(...);                      end
  def admin_upload_url(...);                       end
  def advanced_search_path(...);                   end
  def advanced_search_url(...);                    end
  def analytics_sys_path(...);                     end
  def analytics_sys_url(...);                      end
  def api_migrate_path(...);                       end
  def api_migrate_url(...);                        end
  def bulk_create_manifest_item_path(...);         end
  def bulk_create_manifest_item_url(...);          end
  def bulk_create_upload_path(...);                end
  def bulk_create_upload_url(...);                 end
  def bulk_delete_manifest_item_path(...);         end
  def bulk_delete_manifest_item_url(...);          end
  def bulk_delete_upload_path(...);                end
  def bulk_delete_upload_url(...);                 end
  def bulk_destroy_manifest_item_path(...);        end
  def bulk_destroy_manifest_item_url(...);         end
  def bulk_destroy_upload_path(...);               end
  def bulk_destroy_upload_url(...);                end
  def bulk_edit_manifest_item_path(...);           end
  def bulk_edit_manifest_item_url(...);            end
  def bulk_edit_upload_path(...);                  end
  def bulk_edit_upload_url(...);                   end
  def bulk_fields_manifest_item_path(...);         end
  def bulk_fields_manifest_item_url(...);          end
  def bulk_new_manifest_item_path(...);            end
  def bulk_new_manifest_item_url(...);             end
  def bulk_new_upload_path(...);                   end
  def bulk_new_upload_url(...);                    end
  def bulk_reindex_upload_path(...);               end
  def bulk_reindex_upload_url(...);                end
  def bulk_update_manifest_item_path(...);         end
  def bulk_update_manifest_item_url(...);          end
  def bulk_update_upload_path(...);                end
  def bulk_update_upload_url(...);                 end
  def bulk_upload_index_path(...);                 end
  def bulk_upload_index_url(...);                  end
  def cancel_manifest_path(...);                   end
  def cancel_manifest_url(...);                    end
  def cancel_upload_path(...);                     end
  def cancel_upload_url(...);                      end
  def cancel_user_registration_path(...);          end
  def cancel_user_registration_url(...);           end
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
  def create_enrollment_path(...);                 end
  def create_enrollment_url(...);                  end
  def create_manifest_item_path(...);              end
  def create_manifest_item_url(...);               end
  def create_manifest_path(...);                   end
  def create_manifest_url(...);                    end
  def create_org_path(...);                        end
  def create_org_url(...);                         end
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
  def database_sys_path(...);                      end
  def database_sys_url(...);                       end
  def delete_account_path(...);                    end
  def delete_account_url(...);                     end
  def delete_enrollment_path(...);                 end
  def delete_enrollment_url(...);                  end
  def delete_manifest_item_path(...);              end
  def delete_manifest_item_url(...);               end
  def delete_manifest_path(...);                   end
  def delete_manifest_url(...);                    end
  def delete_org_path(...);                        end
  def delete_org_url(...);                         end
  def delete_select_account_path(...);             end
  def delete_select_account_url(...);              end
  def delete_select_enrollment_path(...);          end
  def delete_select_enrollment_url(...);           end
  def delete_select_manifest_path(...);            end
  def delete_select_manifest_url(...);             end
  def delete_select_org_path(...);                 end
  def delete_select_org_url(...);                  end
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
  def destroy_enrollment_path(...);                end
  def destroy_enrollment_url(...);                 end
  def destroy_manifest_item_path(...);             end
  def destroy_manifest_item_url(...);              end
  def destroy_manifest_path(...);                  end
  def destroy_manifest_url(...);                   end
  def destroy_org_path(...);                       end
  def destroy_org_url(...);                        end
  def destroy_upload_path(...);                    end
  def destroy_upload_url(...);                     end
  def destroy_user_registration_path(...);         end
  def destroy_user_registration_url(...);          end
  def destroy_user_session_path(...);              end
  def destroy_user_session_url(...);               end
  def disk_space_sys_path(...);                    end
  def disk_space_sys_url(...);                     end
  def edit_account_path(...);                      end
  def edit_account_url(...);                       end
  def edit_current_account_path(...);              end
  def edit_current_account_url(...);               end
  def edit_current_org_path(...);                  end
  def edit_current_org_url(...);                   end
  def edit_enrollment_path(...);                   end
  def edit_enrollment_url(...);                    end
  def edit_manifest_item_path(...);                end
  def edit_manifest_item_url(...);                 end
  def edit_manifest_path(...);                     end
  def edit_manifest_url(...);                      end
  def edit_org_path(...);                          end
  def edit_org_url(...);                           end
  def edit_password_path(...);                     end
  def edit_password_url(...);                      end
  def edit_select_account_path(...);               end
  def edit_select_account_url(...);                end
  def edit_select_enrollment_path(...);            end
  def edit_select_enrollment_url(...);             end
  def edit_select_manifest_path(...);              end
  def edit_select_manifest_url(...);               end
  def edit_select_org_path(...);                   end
  def edit_select_org_url(...);                    end
  def edit_select_upload_path(...);                end
  def edit_select_upload_url(...);                 end
  def edit_select_user_path(...);                  end # /users/edit_select
  def edit_select_user_registration_path(...);     end
  def edit_select_user_registration_url(...);      end
  def edit_select_user_url(...);                   end
  def edit_upload_path(...);                       end
  def edit_upload_url(...);                        end
  def edit_user_path(...);                         end
  def edit_user_registration_path(...);            end # /users/edit
  def edit_user_registration_url(...);             end
  def edit_user_url(...);                          end
  def enroll_path(...);                            end
  def enroll_url(...);                             end
  def enrollment_index_path(...);                  end
  def enrollment_index_url(...);                   end
  def environment_sys_path(...);                   end
  def environment_sys_url(...);                    end
  def file_download_path(...);                     end
  def file_download_url(...);                      end
  def files_sys_path(...);                         end
  def files_sys_url(...);                          end
  def finalize_enrollment_path(...);               end
  def finalize_enrollment_url(...);                end
  def headers_sys_path(...);                       end
  def headers_sys_url(...);                        end
  def healthcheck_path(...);                       end
  def healthcheck_url(...);                        end
  def help_index_path(...);                        end
  def help_index_url(...);                         end
  def help_path(...);                              end
  def help_url(...);                               end
  def home_path(...);                              end
  def home_url(...);                               end
  def internals_sys_path(...);                     end
  def internals_sys_url(...);                      end
  def jobs_sys_path(...);                          end
  def jobs_sys_url(...);                           end
  def list_all_account_path(...);                  end
  def list_all_account_url(...);                   end
  def list_all_manifest_path(...);                 end
  def list_all_manifest_url(...);                  end
  def list_all_org_path(...);                      end
  def list_all_org_url(...);                       end
  def list_all_upload_path(...);                   end
  def list_all_upload_url(...);                    end
  def list_org_account_path(...);                  end
  def list_org_account_url(...);                   end
  def list_org_manifest_path(...);                 end
  def list_org_manifest_url(...);                  end
  def list_org_upload_path(...);                   end
  def list_org_upload_url(...);                    end
  def list_own_manifest_path(...);                 end
  def list_own_manifest_url(...);                  end
  def list_own_upload_path(...);                   end
  def list_own_upload_url(...);                    end
  def loggers_sys_path(...);                       end
  def loggers_sys_url(...);                        end
  def mailers_sys_path(...);                       end
  def mailers_sys_url(...);                        end
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
  def metrics_test_path(...);                      end
  def metrics_test_url(...);                       end
  def new_account_path(...);                       end
  def new_account_url(...);                        end
  def new_enrollment_path(...);                    end
  def new_enrollment_url(...);                     end
  def new_manifest_item_path(...);                 end
  def new_manifest_item_url(...);                  end
  def new_manifest_path(...);                      end
  def new_manifest_url(...);                       end
  def new_org_path(...);                           end
  def new_org_url(...);                            end
  def new_password_path(...);                      end
  def new_upload_path(...);                        end
  def new_upload_url(...);                         end
  def new_user_path(...);                          end
  def new_user_registration_path(...);             end # /users/new
  def new_user_registration_url(...);              end
  def new_user_session_path(...);                  end
  def new_user_session_url(...);                   end
  def new_user_url(...);                           end
  def org_index_path(...);                         end
  def org_index_url(...);                          end
  def password_path(...);                          end
  def password_url(...);                           end
  def processes_sys_path(...);                     end
  def processes_sys_url(...);                      end
  def reedit_upload_path(...);                     end
  def reedit_upload_url(...);                      end
  def registration_path(...);                      end
  def registration_url(...);                       end
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
  def settings_sys_path(...);                      end
  def settings_sys_url(...);                       end
  def show_account_path(...);                      end
  def show_account_url(...);                       end
  def show_current_account_path(...);              end
  def show_current_account_url(...);               end
  def show_current_org_path(...);                  end
  def show_current_org_url(...);                   end
  def show_enrollment_path(...);                   end
  def show_enrollment_url(...);                    end
  def show_manifest_item_path(...);                end
  def show_manifest_item_url(...);                 end
  def show_manifest_path(...);                     end
  def show_manifest_url(...);                      end
  def show_org_path(...);                          end
  def show_org_url(...);                           end
  def show_select_account_path(...);               end
  def show_select_account_url(...);                end
  def show_select_enrollment_path(...);            end
  def show_select_enrollment_url(...);             end
  def show_select_manifest_path(...);              end
  def show_select_manifest_url(...);               end
  def show_select_org_path(...);                   end
  def show_select_org_url(...);                    end
  def show_select_upload_path(...);                end
  def show_select_upload_url(...);                 end
  def show_upload_path(...);                       end
  def show_upload_url(...);                        end
  def show_user_registration_path(...);            end
  def show_user_registration_url(...);             end
  def sign_in_local_path(...);                     end # /users/sign_in_local
  def sign_in_local_url(...);                      end
  def sys_index_path(...);                         end
  def sys_index_url(...);                          end
  def system_unavailable_path(...);                end
  def system_unavailable_url(...);                 end
  def tool_index_path(...);                        end
  def tool_index_url(...);                         end
  def unlock_path(...);                            end
  def unlock_url(...);                             end
  def update_account_path(...);                    end
  def update_account_url(...);                     end
  def update_enrollment_path(...);                 end
  def update_enrollment_url(...);                  end
  def update_manifest_item_path(...);              end
  def update_manifest_item_url(...);               end
  def update_manifest_path(...);                   end
  def update_manifest_url(...);                    end
  def update_org_path(...);                        end
  def update_org_url(...);                         end
  def update_sys_path(...);                        end
  def update_sys_url(...);                         end
  def update_upload_path(...);                     end
  def update_upload_url(...);                      end
  def update_user_path(...);                       end
  def update_user_url(...);                        end
  def upload_index_path(...);                      end
  def upload_index_url(...);                       end
  def upload_upload_path(...);                     end
  def upload_upload_url(...);                      end
  def user_registration_path(...);                 end
  def user_registration_url(...);                  end
  def var_sys_path(...);                           end
  def var_sys_url(...);                            end
  def version_health_path(...);                    end
  def version_health_url(...);                     end
  def version_path(...);                           end
  def version_url(...);                            end
  def view_sys_path(...);                          end
  def view_sys_url(...);                           end
  def welcome_path(...);                           end
  def welcome_url(...);                            end
end

if !SIGN_IN_AS
  def sign_in_as_path(...)  = not_implemented
  def sign_in_as_url(...)   = not_implemented
elsif !ONLY_FOR_DOCUMENTATION
  def sign_in_as_path(...); end
  def sign_in_as_url(...);  end
end

# noinspection RubyInstanceMethodNamingConvention
if !SHIBBOLETH
  def user_shibboleth_omniauth_authorize_path(...)  = not_implemented
  def user_shibboleth_omniauth_authorize_url(...)   = not_implemented
  def user_shibboleth_omniauth_callback_path(...)   = not_implemented
  def user_shibboleth_omniauth_callback_url(...)    = not_implemented
elsif !ONLY_FOR_DOCUMENTATION
  def user_shibboleth_omniauth_authorize_path(...); end
  def user_shibboleth_omniauth_authorize_url(...);  end
  def user_shibboleth_omniauth_callback_path(...);  end
  def user_shibboleth_omniauth_callback_url(...);   end
end
# :nocov:
