# app/helpers/http_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HTTP utilities.
#
module HttpHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # HTTP_STATUS_TYPE
  #
  # @type [Hash{Symbol=>Array,Range}]
  #
  HTTP_STATUS_TYPE = {
    perm_redirect: (HTTP_PERM_REDIRECT = [301, 303, 308]),
    temp_redirect: (HTTP_TEMP_REDIRECT = [302, 307]),
  }.deep_freeze

  # HTTP_STATUS_RANGE
  #
  # @type [Hash{Symbol=>Array,Range}]
  #
  HTTP_STATUS_RANGE = {
    info:         (HTTP_CONTINUE = 100..199),
    success:      (HTTP_SUCCESS  = 200..299),
    redirect:     (HTTP_REDIRECT = [*HTTP_PERM_REDIRECT, *HTTP_TEMP_REDIRECT]),
    client_error: (HTTP_CLIENT_ERROR = 400..499),
    server_error: (HTTP_SERVER_ERROR = 500..599),
    error:        (HTTP_ERROR = HTTP_CLIENT_ERROR.min..HTTP_SERVER_ERROR.max)
  }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # info?
  #
  # @param [Integer] code
  #
  # @note Currently unused.
  #
  def info?(code)
    HTTP_CONTINUE.include?(code)
  end

  # success?
  #
  # @param [Integer] code
  #
  # @note Currently unused.
  #
  def success?(code)
    HTTP_SUCCESS.include?(code)
  end

  # redirect?
  #
  # @param [Integer] code
  #
  # @note Currently unused.
  #
  def redirect?(code)
    HTTP_REDIRECT.include?(code)
  end

  # permanent_redirect?
  #
  # @param [Integer] code
  #
  # @note Currently unused.
  #
  def permanent_redirect?(code)
    HTTP_PERM_REDIRECT.include?(code)
  end

  # temporary_redirect?
  #
  # @param [Integer] code
  #
  # @note Currently unused.
  #
  def temporary_redirect?(code)
    HTTP_TEMP_REDIRECT.include?(code)
  end

  # error?
  #
  # @param [Integer] code
  #
  # @note Currently unused.
  #
  def error?(code)
    HTTP_ERROR.include?(code)
  end

  # client_error?
  #
  # @param [Integer] code
  #
  # @note Currently unused.
  #
  def client_error?(code)
    HTTP_CLIENT_ERROR.include?(code)
  end

  # server_error?
  #
  # @param [Integer] code
  #
  # @note Currently unused.
  #
  def server_error?(code)
    HTTP_SERVER_ERROR.include?(code)
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
