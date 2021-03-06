# app/controllers/concerns/user_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for working with authentication and user identity.
#
module UserConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'UserConcern')
  end

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION

    # Defined by Devise.
    #
    # @return [void]
    #
    # @see Devise::Controllers::Helpers#define_helpers
    #
    # @private
    #
    def authenticate_user!; end

    # Defined by Devise.
    #
    # @return [User, nil]
    #
    # @see Devise::Controllers::Helpers#define_helpers
    #
    # @private
    #
    def current_user; end

  end
  # :nocov:

  include FlashConcern
  include BookshareConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return account summary information and account preferences.
  #
  # @param [String] id                If *nil*, assumes the current user.
  #
  # @return [(
  #   Bs::Message::MyAccountSummary,
  #   Bs::Message::MyAccountPreferences,
  #   Bs::Message::TitleDownloadList
  # )]
  # @return [(nil,nil,nil)]
  #
  def get_account_details(id: nil)
    error = []
    warn  = []
    opt   = { no_raise: true }

    # Main account information.
    if id.present?
      opt[:user] = id
      item = bs_api.get_account(**opt)
      if item.error?
        item = bs_api.get_my_organization_member(**opt)
        opt[:user] = item.userAccountId || item.identifier
      end
    else
      item = bs_api.get_my_account(**opt)
      bs_api.discard_exception
    end

    # Ancillary account information.
    if item.error?
      error << item.error_message
      pref = hist = nil
    elsif opt[:user].present?
      pref = bs_api.get_preferences(**opt)
      warn << pref.error_message if pref.error?
      # hist = bs_api.get_download_history(**opt) # TODO: ...
      # warn << hist.error_message if hist.error? # TODO: ...
      hist = nil
      warn << 'No API support for preferences or history'
    else
      pref = bs_api.get_my_preferences(**opt)
      bs_api.discard_exception
      error << pref.error_message if pref.error?
      hist = bs_api.get_my_download_history(**opt)
      bs_api.discard_exception
      error << hist.error_message if hist.error?
    end

    # Display error(s)/warning(s).
    if error.present?
      flash.clear
      flash_now_alert(*error)
    elsif warn.present?
      flash.clear
      flash_now_notice(*warn)
    end

    # Return no data unless main account information is valid.
    item = nil if item.error?
    pref = nil unless item && pref && !pref.error?
    hist = nil unless item && hist && !hist.error?
    return item, pref, hist
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
  def authenticate_admin!
    user = authenticate_user!
    role_failure('Administrator-only feature') unless user.administrator? # TODO: I18n
  end

  # Authenticate then ensure that the user has the :developer role.
  #
  def authenticate_developer!
    user = authenticate_user!
    role_failure('Developer-only feature') unless user.developer? # TODO: I18n
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  private

  ROLE_FAILURE = 'Insufficient privilege for this operation'.freeze

  # Cause an insufficient role for an authenticated session to generate an
  # authentication failure the way Devise does.
  #
  # @param [String, nil] message    Default: 'devise.failure.unauthenticated'
  #
  # == Implementation Notes
  # This method sets `session['app.devise.redirect']` in order to prevent
  # SessionConcern#after_sign_in_path_for from specifying the current (failed)
  # page as the redirect from DeviseController#require_no_authentication.
  #
  def role_failure(message = nil)
    session['app.devise.failure.message'] = message ||= ROLE_FAILURE
    session['app.devise.redirect'] = dashboard_path
    throw(:warden, message: message)
  end

end

__loading_end(__FILE__)
