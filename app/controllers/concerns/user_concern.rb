# app/controllers/concerns/user_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for working with authentication and user identity.
#
module UserConcern

  extend ActiveSupport::Concern

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
    #--
    # noinspection RubyUnusedLocalVariable
    #++
    def authenticate_user!(opts = {}); end

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
  # :section:
  # ===========================================================================

  public

  # Return account summary information and account preferences.
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
  def get_account_details(id: nil, fast: nil, meth: nil)
    Log.debug do
      "#{meth || __method__}: id = #{id.inspect}, fast = #{fast.inspect}"
    end
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
  # authentication failure the way Devise does.
  #
  # @param [String, Symbol, nil] msg  Default: 'devise.failure.unauthenticated'
  #
  # === Implementation Notes
  # This method sets `session['app.devise.redirect']` in order to prevent
  # SessionConcern#after_sign_in_path_for from specifying the current (failed)
  # page as the redirect from DeviseController#require_no_authentication.
  #
  def role_failure(msg = nil)
    if msg.nil?
      msg = config_text(:user, :role_failure)
    elsif msg.is_a?(Symbol)
      msg = config_text(:user, :privileged, role: msg).capitalize
      msg = "#{params[:action]}: #{msg}" if params[:action]
    end
    session['app.devise.failure.message'] = msg
    session['app.devise.redirect']        = dashboard_path
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
