# app/helpers/cookie_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for working with authentication strategies.
#
module CookieHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Common cookie header settings.
  #
  # @type [Hash{Symbol=>Any}]
  #
  # @see Rack::Utils#add_cookie_to_header
  #
  COOKIE_OPTIONS = { path: '/', same_site: :strict, secure: true }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the current value of the cookie from the request.
  #
  # @param [Symbol, String] key
  #
  # @return [Any]
  #
  def get_cookie(key)
    value = cookie_value(key)
    return value unless value.nil?
    from_request = cookies[key.to_s]
    remember_cookie(key, from_request) unless from_request.nil?
  end

  # Set the cookie in the request and the response.
  #
  # @param [Symbol, String] key
  # @param [Any]            value     Defaults to `opt[:value]`.
  # @param [Hash]           opt       To Rack::Response::Helpers#set_cookie.
  #
  # @option opt [Any] :value          Defaults to *value* or *true* if missing.
  #
  # @return [Any]                     The cookie value.
  #
  def set_cookie(key, value = nil, **opt)
    value = opt[:value] if value.nil?
    value = true        if value.nil?
    return value if cookie_value(key) == value
    opt.reverse_merge!(COOKIE_OPTIONS).merge!(value: value)
    response.set_cookie(key, opt)
    remember_cookie(key, value)
  end

  # Remove the cookie from the request and indicate removal in the response.
  #
  # @param [Symbol, String] key
  # @param [Hash]           opt       To Rack::Response::Helpers#delete_cookie.
  #
  # @return [void]
  #
  def delete_cookie(key, **opt)
    opt.reverse_merge!(COOKIE_OPTIONS)
    response.delete_cookie(key, opt)
    forget_cookie(key)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Session section which reports on cookies that have been set manually or
  # from the request.
  #
  # @type [String]
  #
  SS_COOKIES = 'cookies'

  # Get the saved value of the cookie from `session`.
  #
  # @param [String, Symbol] key
  #
  # @return [Any]
  #
  def cookie_value(key)
    session[SS_COOKIES][key.to_s] if session[SS_COOKIES].is_a?(Hash)
  end

  # Save a copy of the cookie value in `session`.
  #
  # @param [String, Symbol] key
  # @param [Any]            value
  #
  # @return [Any]
  #
  def remember_cookie(key, value)
    session[SS_COOKIES] = {} unless session[SS_COOKIES].is_a?(Hash)
    session[SS_COOKIES][key.to_s] = value
  end

  # Remove the copy of the cookie value from `session`.
  #
  # @param [String, Symbol] key
  #
  # @return [Any]
  #
  def forget_cookie(key)
    session[SS_COOKIES].delete(key.to_s) if session[SS_COOKIES].is_a?(Hash)
    session.delete(SS_COOKIES)           if session[SS_COOKIES].blank?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
