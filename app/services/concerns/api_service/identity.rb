# app/services/concerns/api_service/identity.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Identity
#
module ApiService::Identity

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The user that caused the #api method to be invoked.
  #
  # @return [User, nil]
  #
  attr_reader :user

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract the user name to be used for API parameters.
  #
  # @param [User, String] user
  #
  # @return [String]
  #
  def name_of(user)
    user.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Set the user for the current session.
  #
  # @param [User, nil] u
  #
  # @raise [RuntimeError]             If *u* is invalid.
  #
  # @return [void]
  #
  def set_user(u)
    raise "argument must be a User not a #{u.class}" if u && !u.is_a?(User)
    @user = u
  end

  # The current OAuth2 access bearer token (if applicable).
  #
  # @return [String, nil]
  #
  def access_token
    may_be_overridden # but only if a new authentication mechanism requires it
  end

  # The current OAuth2 refresher token (if applicable).
  #
  # @return [String, nil]
  #
  def refresh_token
    may_be_overridden # but only if a new authentication mechanism requires it
  end

end

__loading_end(__FILE__)
