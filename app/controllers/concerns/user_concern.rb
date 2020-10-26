# app/controllers/concerns/user_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# UserConcern
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
    def authenticate_user!; end

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
  # @return [Array<(
  #   Bs::Message::MyAccountSummary,
  #   Bs::Message::MyAccountPreferences,
  #   Bs::Message::TitleDownloadList
  # )>]
  # @return [nil]
  #
  def get_account_details(id: nil)
    error = []
    warn  = []
    opt   = { no_raise: true }

    # Main account information.
    if id.present?
      opt[:user] = id
      item = bs_api.get_account(**opt)
      # noinspection RubyResolve
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
    unless item.error?
      pref = nil if pref&.error?
      hist = nil if hist&.error?
      return item, pref, hist
    end
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
    data   = session['omniauth.auth']
    warden = request.env['warden']
    @user  = data && warden&.set_user(User.from_omniauth(data))
  end

end

__loading_end(__FILE__)
