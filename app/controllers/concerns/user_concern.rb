# app/controllers/concerns/user_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for working with authentication and user identity.
#
module UserConcern

  extend ActiveSupport::Concern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # Defined by Devise.
    #
    # @return [User, nil]
    #
    # @see Devise::Controllers::Helpers#define_helpers
    #
    # @private
    #
    #--
    # noinspection RubyUnusedLocalVariable
    #++
    def authenticate_user!(opts = {}); end

    # Defined by Devise.
    #
    # @return [User, nil]
    #
    # @see Devise::Controllers::Helpers#define_helpers
    #
    # @private
    #
    def current_user; end

    # :nocov:
  end

  include FlashHelper
  include RoleHelper

  include AuthConcern
  include BookshareConcern

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
  # @return [Array<(
  #   Bs::Message::MyAccountSummary,
  #   Bs::Message::MyAccountPreferences,
  #   Bs::Message::TitleDownloadList
  # )>]
  # @return [Array<(nil,nil,nil)>]
  #
  def get_account_details(id: nil, fast: nil, meth: nil)
    meth ||= calling_method
    error  = []
    warn   = []
    opt    = { no_raise: true }

    # Main account information.
    if id.present?
      opt[:user] = id
      item = bs_api.get_account(**opt)
      if item.error?
        item = bs_api.get_my_organization_member(**opt)
        opt[:user] = item.userAccountId.presence || item.identifier.presence
      end
    else
      item = bs_api.get_my_account(**opt)
      id   = item.identifier.presence
    end

    # Ancillary account information.
    pref = hist = nil
    if item.error?
      error << item.exec_report
    elsif opt[:user].present?
      pref = bs_api.get_preferences(**opt)
      warn << pref.exec_report if pref.error?
      # hist = bs_api.get_download_history(**opt) # TODO: ...
      # warn << hist.error_message if hist.error? # TODO: ...
      hist = nil
      warn << 'No API support for preferences or history'
    elsif !fast
      pref = bs_api.get_my_preferences(**opt)
      error << pref.exec_report if pref.error?
      hist = bs_api.get_my_download_history(**opt)
      error << hist.exec_report if hist.error?
    end

    # Display error(s)/warning(s).
    if error.present? || warn.present?
      id ||= item.identifier.presence || current_user.try(:email)
      tag = (" for #{id.inspect}" if id.present?)
      tag = "Bookshare service error#{tag}:"
      if error.present?
        flash_now_alert(tag, *error, meth: meth)
      elsif warn.present?
        flash_now_notice(tag, *warn, meth: meth)
      end
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

  ROLE_FAILURE = 'Insufficient privilege for this operation'.freeze

  # Cause an insufficient role for an authenticated session to generate an
  # authentication failure the way Devise does.
  #
  # @param [String, Symbol, nil] msg  Default: 'devise.failure.unauthenticated'
  #
  # == Implementation Notes
  # This method sets `session['app.devise.redirect']` in order to prevent
  # SessionConcern#after_sign_in_path_for from specifying the current (failed)
  # page as the redirect from DeviseController#require_no_authentication.
  #
  def role_failure(msg = nil)
    if msg.is_a?(Symbol)
      role = msg.to_s.capitalize
      msg  = +''
      msg << params[:action].to_s << ': ' if params[:action]
      msg << "#{role}-only feature" # TODO: I18n
    end
    session['app.devise.failure.message'] = msg ||= ROLE_FAILURE
    session['app.devise.redirect'] = dashboard_path
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
