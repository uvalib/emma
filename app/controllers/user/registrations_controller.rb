# app/controllers/user/registrations_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Individual EMMA user account maintenance.
#
# @see file:app/views/user/registrations/**
#
class User::RegistrationsController < Devise::RegistrationsController

  include UserConcern
  include SessionConcern
  include RunStateConcern

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  prepend_before_action :require_no_authentication, only: %i[create]
  prepend_before_action :authenticate_scope!,       only: %i[edit edit_select update destroy]

  before_action :update_user
  before_action :authenticate_user!, except: %i[new]

  before_action :configure_create_params, only: %i[new  create]
  before_action :configure_update_params, only: %i[edit update]

  # ===========================================================================
  # :section: Devise::RegistrationsController overrides
  # ===========================================================================

  public

  # === GET /users/new
  # === GET /users/sign_up
  #
  # @see #new_user_path               Route helper
  # @see #new_user_registration_path  Route helper
  #
  def new
    __log_activity
    __debug_route
    if current_user
      message = 'You already have an EMMA account' # TODO: I18n
      return redirect_back(fallback_location: root_path, alert: message)
    end
    super
  end

  # === POST /users
  #
  # @see #create_user_path                Route helper
  # @see #create_user_registration_path   Route helper
  #
  def create
    __log_activity
    __debug_route
    __debug_request
    super
    set_flash_notice(user: resource.uid)
  rescue => error
    auth_failure_redirect(message: error)
  end

  # === GET /users/edit/:id
  # === GET /users/edit
  #
  # @see #edit_user_path                Route helper
  # @see #edit_user_registration_path   Route helper
  #
  def edit
    __log_activity
    __debug_route
    id = (params[:selected] || params[:id]).to_s
    return redirect_to edit_select_user_path if show_menu?(id)
    if (user = positive(id))
      @item = User.find_record(user) or raise "invalid selection #{id.inspect}"
    else
      @item = current_user
    end
    super
  end

  # === POST  /users/update/:id
  # === PATCH /users/update/:id
  # === PUT   /users/update/:id
  # === PUT   /users
  #
  # @see #update_user_path            Route helper
  # @see #user_registration_path      Route helper
  #
  def update
    __log_activity
    __debug_route
    __debug_request
    update_resource(resource, account_update_params) or raise set_flash_alert
    set_flash_notice(user: resource.uid)
    redirect_back(fallback_location: dashboard_path)
  rescue => error
    auth_failure_redirect(message: error)
  end

  # === GET /users/resign
  #
  def delete
    __log_activity
    __debug_route
  end

  # === DELETE /users
  #
  def destroy
    __log_activity
    __debug_route
    __debug_request
    user = resource&.uid&.dup || 'unknown'
    super
    set_flash_notice(user: user)
  rescue => error
    auth_failure_redirect(message: error)
  end

  # === GET /users/cancel
  #
  # Forces the session data which is usually expired after sign in to be
  # expired now. This is useful if the user wants to cancel oauth signing in/up
  # in the middle of the process, removing all OAuth session data.
  #
  # @see #cancel_user_registration_path   Route helper
  #
  def cancel
    __log_activity
    __debug_route
    __debug_request
    super
  rescue => error
    auth_failure_redirect(message: error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /users/edit_select
  #
  # @see #edit_select_user_path       Route helper
  #
  def edit_select
    __log_activity
    __debug_route
  end

  # ===========================================================================
  # :section: Devise::RegistrationsController overrides
  # ===========================================================================

  protected

  # Include User attributes to allowed parameters for account creation.
  #
  def configure_create_params
    allow_params(:sign_up, except: :id)
  end

  # Include User attributes to allowed parameters for account modification.
  #
  def configure_update_params
    allow_params(:account_update)
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether URL parameters require that a menu should be shown rather
  # than operating on an explicit set of identifiers.
  #
  # @param [String, Array<String>, nil] id_params  Default: `params[:id]`.
  #
  def show_menu?(id_params = nil)
    id_params ||= params[:selected] || params[:id]
    Array.wrap(id_params).include?('SELECT')
  end

  # Specify acceptable URL parameters.
  #
  # @param [Symbol]                     action  Devise action name.
  # @param [Array<Symbol>, Symbol, nil] keys    Default: `User.field_names`
  # @param [Array<Symbol>, Symbol, nil] except  Default: [:id, :email]
  #
  # @return [ActiveSupport::HashWithIndifferentAccess]
  #
  # @yield [params]
  # @yieldparam [ActionController::Parameters] params
  # @yieldreturn [Hash,nil]
  #
  # === Usage Notes
  # Due to the current uniqueness constraint on 'index_users_on_email', the
  # email address can't be updated.
  #
  def allow_params(action, keys: nil, except: nil, &blk)
    keys   &&= Array.wrap(keys)
    keys   ||= User.field_names
    except &&= Array.wrap(except)
    except ||= %i[id email]
    devise_parameter_sanitizer.permit(action, keys: keys, except: except, &blk)
  end

end

__loading_end(__FILE__)
