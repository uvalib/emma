# app/services/bookshare_service/identity.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Identity
#
module BookshareService::Identity

  include ApiService::Identity

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract the user name to be used for API parameters.
  #
  # @param [User, String, nil] user
  #
  # @return [String]
  #
  def name_of(user)
    name = user.is_a?(Hash) ? user['uid'] : user
    name.to_s.presence || DEFAULT_USER
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
    super
    @user = @user&.bookshare_user
  end

end

__loading_end(__FILE__)
