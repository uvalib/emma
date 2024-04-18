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

  # A mapping of status ranges to their related HTTP statuses.
  #
  # @type [Hash{Symbol=>Array,Range}]
  #
  HTTP_STATUS_CODE_RANGE = {
    info:          (100..199),
    success:       (200..299),
    perm_redirect: [301, 303, 308],
    temp_redirect: [302, 307],
    client_error:  (400..499),
    server_error:  (500..599),
  }.tap { |hash|
    hash[:redirect] = [*hash[:perm_redirect], *hash[:temp_redirect]]
    hash[:error]    = (hash[:client_error].min..hash[:server_error].max)
  }.deep_freeze

  # A mapping of HTTP status to its symbolic form.
  #
  # @type [Hash{Integer=>Symbol}]
  #
  HTTP_STATUS_CODE_TO_SYMBOL = Rack::Utils::SYMBOL_TO_STATUS_CODE.invert.freeze

  # A mapping of status ranges to their related symbolic HTTP statuses.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  HTTP_SYMBOLIC_CODE_RANGE =
    HTTP_STATUS_CODE_RANGE.transform_values { |range|
      HTTP_STATUS_CODE_TO_SYMBOL.slice(*range).values
    }.deep_freeze

  # Indicate whether the value represents an HTTP status code which is part of
  # the given named range.
  #
  # @param [Symbol]   range
  # @param [any, nil] code            Symbol, Integer
  #
  def http_status?(range, code)
    entry = error = nil
    case code
      when nil     then return false
      when Integer then entry = HTTP_STATUS_CODE_RANGE[range]
      when Symbol  then entry = HTTP_SYMBOLIC_CODE_RANGE[range]
      else              error = "invalid HTTP code #{code.inspect}"
    end
    Log.debug { error || "invalid HTTP range #{range.inspect}" } unless entry
    entry&.include?(code) || false
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the value represents an HTTP 1xx status.
  #
  # @param [any, nil] code            Symbol, Integer
  #
  # @note Currently unused.
  #
  def http_info?(code)
    http_status?(:info, code)
  end

  # Indicate whether the value represents an HTTP 2xx status.
  #
  # @param [any, nil] code            Symbol, Integer
  #
  def http_success?(code)
    http_status?(:success, code)
  end

  # Indicate whether the value represents an HTTP 3xx status.
  #
  # @param [any, nil] code            Symbol, Integer
  #
  def http_redirect?(code)
    http_status?(:redirect, code)
  end

  # Indicate whether the value represents an HTTP 301, 303 or 308 status.
  #
  # @param [any, nil] code            Symbol, Integer
  #
  def http_permanent_redirect?(code)
    http_status?(:perm_redirect, code)
  end

  # Indicate whether the value represents an HTTP 302 or 307 status.
  #
  # @param [any, nil] code            Symbol, Integer
  #
  # @note Currently unused.
  #
  def http_temporary_redirect?(code)
    http_status?(:temp_redirect, code)
  end

  # Indicate whether the value represents an HTTP 403 status.
  #
  # @param [any, nil] code            Symbol, Integer
  #
  def http_forbidden?(code)
    (code == :forbidden) || (code == 403)
  end

  # Indicate whether the value represents a failure HTTP status.
  #
  # @param [any, nil] code            Symbol, Integer
  #
  # @note Currently unused.
  #
  def http_error?(code)
    http_status?(:error, code)
  end

  # Indicate whether the value represents an HTTP 4xx status.
  #
  # @param [any, nil] code            Symbol, Integer
  #
  # @note Currently unused.
  #
  def http_client_error?(code)
    http_status?(:client_error, code)
  end

  # Indicate whether the value represents an HTTP 5xx status.
  #
  # @param [any, nil] code            Symbol, Integer
  #
  # @note Currently unused.
  #
  def http_server_error?(code)
    http_status?(:server_error, code)
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
