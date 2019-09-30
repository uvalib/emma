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

  include ApiHelper

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
  #   ApiMyAccountSummary,
  #   ApiMyAccountPreferences,
  #   ApiTitleDownloadList
  # )>]
  #
  # noinspection RubyNilAnalysis
  def get_account_details(id: nil)
    pref = hist = error = warn = nil
    if id
      item = api.get_account(user: id)
      item = api.get_my_organization_member(username: id) if item.error?
      if item.error?
        error = item.error_message
      else
        pref  = nil # TODO: need API support
        hist  = nil # TODO: need API support
        warn  = 'No API support for preferences or history'
      end
    else
      if (item = api.get_my_account).error?
        error = item.error_message
      else
        pref  = api.get_my_preferences
        error = pref.error_message if pref.error?
        hist  = api.get_my_download_history
        error = hist.error_message if hist.error?
      end
    end
    if error || warn
      flash.clear
      flash.now[error ? :alert : :notice] = error || warn
    end
    return item, pref, hist unless item.error?
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
