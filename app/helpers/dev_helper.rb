# app/helpers/dev_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for managing developer status.
#
module DevHelper

  include CookieHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The header cookie indicating developer-only behaviors.
  #
  # @type [String]
  #
  DEV_COOKIE = 'app.user.dev'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this is a developer client.
  #
  def dev_client?
    true?(get_cookie(DEV_COOKIE))
  end

  # Set a cookie indicating a developer client.
  #
  # @param [User, nil] user
  #
  # @return [Boolean]
  #
  def remember_dev(user = nil)
    (user.nil? || user.developer?) && set_cookie(DEV_COOKIE)
  end

  # Remove the cookie indicating a developer client.
  #
  # @return [void]
  #
  # @note Currently unused.
  # :nocov:
  def forget_dev(...)
    delete_cookie(DEV_COOKIE)
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
