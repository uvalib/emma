# app/helpers/cookie_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for working with request cookies.
#
module CookieHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the current value of the cookie from the request.
  #
  # @param [Symbol, String] key
  #
  # @return [any, nil]
  #
  def get_cookie(key)
    cookies.encrypted[key.to_s]
  end

  # Set the cookie in the request and the response.
  #
  # @param [Symbol, String] key
  # @param [any, nil]       value     Defaults to *true*.
  #
  # @return [any]                     The cookie value.
  # @return [nil]                     If the cookie could not be set.
  #
  def set_cookie(key, value = nil)
    value = true if value.nil?
    cookies.encrypted[key.to_s] = value
  rescue ActionDispatch::Cookies::CookieOverflow => error
    Log.warn { "#{__method__}(#{key.inspect}): could not set_cookie" }
    Log.warn { "#{__method__}(#{key.inspect}): #{error.full_message}" }
  end

  # Remove the cookie from the request and indicate removal in the response.
  #
  # @param [Symbol, String] key
  #
  # @return [void]
  #
  # @note Currently used only by DevHelper#forget_dev.
  # :nocov:
  def delete_cookie(key)
    cookies.encrypted[key.to_s] = nil
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
