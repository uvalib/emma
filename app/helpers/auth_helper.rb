# app/helpers/auth_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for working with authentication strategies.
#
module AuthHelper

  # @private
  def self.included(base)

    __included(base, 'AuthHelper')

    base.send(:extend, self)

  end

  include Emma::Common
  extend self

  # ===========================================================================
  # :section: OmniAuth::Strategies::Bookshare methods
  # ===========================================================================

  public

  # Generate the authentication data to be associated with the given user.
  #
  # @param [User] user
  #
  # @return [OmniAuth::AuthHash, nil]
  #
  def auth_hash(user)
    OmniAuth::Strategies::Bookshare.auth_hash(user) if user.is_a?(User)
  end

  # Generate an auth hash based on fixed information.
  #
  # @param [ActionController::Parameters, Hash, String, User] src
  # @param [String, nil] token
  #
  # @return [OmniAuth::AuthHash, nil]
  #
  def synthetic_auth_hash(src, token = nil)
    OmniAuth::Strategies::Bookshare.synthetic_auth_hash(src, token)
  end

  # Table of user names/tokens acquired for use in non-production deploys.
  #
  # Token are taken from the User table entries that have an :access_token
  # value.  If BOOKSHARE_TEST_USERS is supplied, it is used to prime (or
  # update) database table.
  #
  # @param [Boolean, nil] refresh     If *true*, re-read the database.
  #
  # @return [Hash{String=>Hash}]
  #
  # == Usage Notes
  # Because the logic is only performed once, direct changes to the User
  # table will not be reflected here, however changes made indirectly via
  # #stored_auth_update and/or #stored_auth_update_user will change both
  # the value returned by this method and the associated User table entry.
  #
  def stored_auth(refresh = false)
    refresh = stored_auth_fetch if refresh.is_a?(TrueClass)
    OmniAuth::Strategies::Bookshare.stored_auth(refresh.presence)
  end

  # Produce a stored_auth table entry value.
  #
  # @param [String] token
  #
  # @return [Hash{Symbol=>String}]
  #
  def stored_auth_entry_value(token)
    OmniAuth::Strategies::Bookshare.stored_auth_entry_value(token)
  end

  # auth_default_options
  #
  # @return [OmniAuth::Strategy::Options]
  #
  def auth_default_options
    OmniAuth::Strategies::Bookshare.default_options
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get user names/tokens from the database.
  #
  # @return [Hash{String=>Hash}]
  #
  def stored_auth_fetch
    User.where.not(access_token: nil).order(:id).map { |u|
      [u.uid, stored_auth_entry_value(u.access_token)]
    }.to_h
  end

  # Add or update one or more user name/token entries.
  #
  # @param [Hash{String=>String}, nil] pairs
  #
  # @return [void]
  #
  def stored_auth_update(pairs)
    reject_blanks(pairs).each_pair do |user, token|
      token = { access_token: token } unless token.is_a?(Hash)
      User.update(user, token.slice(:access_token, :refresh_token))
    end
  end

  # Add or update a user name/token entry.
  #
  # If input parameters were invalid then no change will be made.
  #
  # @param [OmniAuth::AuthHash, String]         user
  # @param [String, ::OAuth2::AccessToken, nil] token
  #
  # @return [Hash{String=>Hash}]  The updated set of saved user/tokens.
  #
  # == Variations
  #
  # @overload stored_auth_update_user(auth)
  #   @param [OmniAuth::AuthHash]            auth   User/token to add
  #
  # @overload stored_auth_update_user(auth)
  #   @param [String]                        user   User to add.
  #   @param [String, ::OAuth2::AccessToken] token  Associated token.
  #
  def stored_auth_update_user(user, token = nil)
    if user.is_a?(OmniAuth::AuthHash)
      user, token = [user.uid, user.credentials.token]
    elsif token.is_a?(OAuth2::AccessToken)
      # noinspection RubyNilAnalysis
      token = token.token
    end
    if user.blank? || token.blank?
      Log.warn do
        msg = %W(#{__method__}: missing)
        msg << 'user'  if user.blank?
        msg << 'and'   if user.blank? && token.blank?
        msg << 'token' if token.blank?
        msg.join(' ')
      end
      return
    end

    # Create or update the dynamic table entry.
    if stored_auth[user].blank?
      # noinspection RubyYardParamTypeMatch
      stored_auth[user] = stored_auth_entry_value(token)
    elsif stored_auth[user][:access_token] != token
      stored_auth[user][:access_token] = token
    else
      token = nil
    end

    # Update the database table if there was a change, then return with the
    # relevant entry.
    User.find_or_create_by(email: user) { |u| u.access_token = token } if token
    stored_auth.slice(user)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DEV_COOKIE = 'app.user.dev'

  # Note whether the user is a developer.
  #
  # @param [User, nil] user
  #
  # @return [true, nil]
  #
  def check_dev(user = nil)
    session[DEV_COOKIE] = true if (user || resource)&.developer?
  end

  # Set a cookie indicating a developer client.
  #
  # @return [void]
  #
  def remember_dev
    return unless true?(session[DEV_COOKIE])
    response.set_cookie(DEV_COOKIE, { value: true })
  end

  # Remove the cookie indicating a developer client.
  #
  # @return [void]
  #
  def forget_dev
    session.delete(DEV_COOKIE)
    cookies.delete(DEV_COOKIE)
    response.delete_cookie(DEV_COOKIE)
  end

  # Indicate whether this is a developer client.
  #
  def dev_client?
    true?(cookies[DEV_COOKIE])
  end

end

__loading_end(__FILE__)
