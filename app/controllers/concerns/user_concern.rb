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

  include BookshareHelper

  # Non-functional hints for RubyMine.
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
  # noinspection RubyNilAnalysis
  def get_account_details(id: nil)
    error = []
    warn  = []
    opt   = { no_raise: true }
    opt[:user] = id if id

    # Main account information.
    if id
      item = api.get_account(**opt)
      item = api.get_my_organization_member(**opt) if item.error?
    else
      item = api.get_my_account(**opt)
      api.discard_exception
    end

    # Ancillary account information.
    if item.error?
      error << item.error_message
      pref = hist = nil
    elsif id
      pref = api.get_preferences(**opt)
      warn << pref.error_message if pref.error?
      # hist = api.get_download_history(**opt) # TODO: ...
      # warn << hist.error_message if hist.error? # TODO: ...
      hist = nil
      warn << 'No API support for preferences or history'
    else
      pref = api.get_my_preferences(**opt)
      api.discard_exception
      error << pref.error_message if pref.error?
      hist = api.get_my_download_history(**opt)
      api.discard_exception
      error << hist.error_message if hist.error?
    end

    # Display error(s)/warning(s).
    if (error = error.presence) || (warn = warn.presence)
      flash.clear
      flash.now[error ? :alert : :notice] = error || warn
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
