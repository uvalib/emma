# app/controllers/concerns/user_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for working with authentication and user identity.
#
module UserConcern

  extend ActiveSupport::Concern

  include Emma::Project

  include FlashHelper
  include IdentityHelper

  include AuthConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # Defined by Devise.
    #
    # @return [User, nil]
    #
    # @private
    # @see Devise::Controllers::Helpers#define_helpers
    #
    def current_user; end

    # :nocov:
  end

  # ===========================================================================
  # :section: Devise overrides
  # ===========================================================================

  public

  # Authenticate the current session user, failing if the user is inactive.
  #
  # @return [User, nil]
  #
  # @see Devise::Controllers::Helpers#define_helpers
  #
  def authenticate_user!(opts = {})
    super&.tap do |user|
      check_inactive(user) if user
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign out *user* if the account is marked as inactive.
  #
  # @param [User] user
  #
  def check_inactive(user)
    return unless user&.status&.to_sym == :inactive
    cause  = :inactive_user
    cause  = :inactive_org     if user.org&.status&.to_sym == :inactive
    cause  = :inactive_manager if user.manager? && (cause == :inactive_org)
    mail   = nil
    unless cause == :inactive_manager
      mans = user.org&.managers&.presence&.map(&:email)&.map(&:inspect)
      mail = mans&.pop
      mail = mans.join(', ') << " or #{mail}" if mans
    end
    mail ||= HELP_EMAIL.inspect
    msg    = cause.is_a?(Symbol) ? config_term(:user, cause) : cause.to_s
    msg    = msg.sub(/[[:punct:]]* *$/, " at: #{mail}.") if mail.present?
    sign_out
    authentication_failure(msg: msg)
  end

  # Return Bookshare account summary information and account preferences.
  #
  # @note Defunct
  #
  # @param [String]         id        If *nil*, assumes the current user.
  # @param [Boolean]        fast      If *true*, don't get history/preferences.
  # @param [Symbol, String] meth      Calling method.
  #
  # _return [Array<(
  #   Bs::Message::MyAccountSummary,
  #   Bs::Message::MyAccountPreferences,
  #   Bs::Message::TitleDownloadList
  # )>]
  # @return [Array(nil,nil,nil)]
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def get_account_details(id: nil, fast: nil, meth: nil)
    return nil, nil, nil # TODO: get_account_details ???
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Update the current user with previously-acquired authentication data.
  #
  # @return [void]
  #
  def update_user
    @user =
      warden.user || warden.set_user(user_from_session, run_callbacks: false)
  end

  # Authenticate then ensure that the user does not have the :staff role.
  #
  # @param [Hash] opt                 Passed to #authenticate_user!
  #
  def authenticate_download!(**opt)
    authenticate_user!(**opt)
    role_failure if current_user.role_prototype == :staff
  end

  # Authenticate then ensure that the user has the :administrator role.
  #
  # @param [Hash] opt                 Passed to #authenticate_user!
  #
  def authenticate_admin!(**opt)
    authenticate_user!(**opt)
    role_failure(:administrator) unless administrator?
  end

  # Authenticate then ensure that the user has the :developer role.
  #
  # @param [Hash] opt                 Passed to #authenticate_user!
  #
  # @note Currently unused.
  #
  def authenticate_dev!(**opt)
    authenticate_user!(**opt)
    role_failure(:developer) unless developer?
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  private

  # Cause an insufficient role for an authenticated session to generate an
  # authentication failure.
  #
  # @param [String, Symbol, nil] role
  #
  def role_failure(role = nil)
    if role.is_a?(Symbol)
      msg = config_term(:user, :privileged, role: role)&.capitalize
    else
      msg = role&.to_s
    end
    msg ||= config_term(:user, :role_failure)
    msg   = "#{params[:action]}: #{msg}" if params[:action]
    authentication_failure(msg: msg, path: dashboard_path)
  end

  # Generate an authentication failure the way Devise does.
  #
  # @param [String, nil] msg          Default: 'devise.failure.unauthenticated'
  # @param [String, nil] path         Default: `root_path`
  #
  # === Implementation Notes
  # This method sets `session['app.devise.redirect']` in order to prevent
  # SessionConcern#after_sign_in_path_for from specifying the current (failed)
  # page as the redirect from DeviseController#require_no_authentication.
  #
  def authentication_failure(msg: nil, path: nil)
    session['app.devise.failure.message'] = msg
    session['app.devise.redirect']        = path || root_path
    throw(:warden, message: msg)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
