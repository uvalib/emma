# app/controllers/user/registrations_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class User::RegistrationsController < Devise::RegistrationsController

  include FlashConcern
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

  # == GET /user/sign_up
  #
  def new
    __debug_route
    if current_user
      message = 'You already have an EMMA account' # TODO: I18n
      return redirect_back(fallback_location: root_path, alert: message)
    end
    super
  end

  # == POST /user
  #
  def create
    __debug_route
    __debug_request
    super
    set_flash_notice(user: resource.uid)
  rescue => error
    auth_failure_redirect(message: error)
    re_raise_if_internal_exception(error)
  end

  # == GET /user/edit
  #
  def edit
    __debug_route
    id = (params[:selected] || params[:id]).to_s
    return redirect_to user_edit_select_path if show_menu?(id)
    if (user = positive(id))
      @item = User.find_record(user) or raise "invalid selection #{id.inspect}"
    else
      @item = current_user
    end
    super
  end

  # == PUT /user
  #
  def update
    __debug_route
    __debug_request
    update_resource(resource, account_update_params) or raise set_flash_alert
    set_flash_notice(user: resource.uid)
    redirect_back(fallback_location: dashboard_path)
  rescue => error
    auth_failure_redirect(message: error)
    re_raise_if_internal_exception(error)
  end

  # == GET /user/resign
  #
  def delete
    __debug_route
  end

  # == DELETE /user
  #
  def destroy
    __debug_route
    __debug_request
    user = resource&.uid&.dup || 'unknown'
    super
    set_flash_notice(user: user)
  rescue => error
    auth_failure_redirect(message: error)
    re_raise_if_internal_exception(error)
  end

  # == GET /user/cancel
  #
  # Forces the session data which is usually expired after sign in to be
  # expired now. This is useful if the user wants to cancel oauth signing in/up
  # in the middle of the process, removing all OAuth session data.
  #
  def cancel
    __debug_route
    __debug_request
    super
  rescue => error
    auth_failure_redirect(message: error)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /user/edit_select
  #
  def edit_select
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

  # Indicate whether URL parameters indicate that a menu should be shown rather
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
  # @yield [params]
  # @yieldparam [ActionController::Parameters] params
  # @yieldreturn [Array<Symbol>]
  #
  # @return [void]
  #
  # == Usage Notes
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
