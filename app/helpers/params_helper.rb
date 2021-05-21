# app/helpers/params_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper support methods related to `params` and `session`.
#
module ParamsHelper

  # @private
  def self.included(base)
    __included(base, 'ParamsHelper')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Request parameters that are not relevant to the application.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_PARAMETERS = %i[
    controller
    action
    format
    utf8
    commit
    _method
    authenticity_token
    modal
  ].sort.freeze

  # Used as the first character of a session value that has been compressed.
  #
  # @type [String]
  #
  #--
  # noinspection RubyQuotedStringsInspection
  #++
  COMPRESSION_MARKER = "\u0007"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the current request is from client-side scripting.
  #
  def request_xhr?
    !!request.xhr?
  end

  # Indicate whether the current request is a normal HTTP GET that coming from
  # the client browser session.
  #
  def route_request?
    request.get? && !request_xhr? && !modal?
  end

  # Indicate whether the current request originates from an application page.
  #
  def local_request?
    request.referer.to_s.start_with?(root_url)
  end

  # Indicate whether the current request originates from an application page.
  #
  def same_request?
    (request.referer == request.url) || (request.referer == request.fullpath)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The full request URL without request parameters.
  #
  # @return [String]
  #
  def request_path
    [request.base_url, request.path].join
  end

  # All request parameters (including :controller and :action) as a Hash.
  #
  # @return [Integer]
  #
  def request_parameter_count(p = nil)
    p ||= respond_to?(:params) ? params : {}
    p.keys.size
  end

  # All request parameters (including :controller and :action) as a Hash.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Default: `params`.
  #
  # @return [Hash{Symbol=>String}]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def request_parameters(p = nil)
    p ||= respond_to?(:params) ? params : {}
    p = p.to_unsafe_h if p.respond_to?(:to_unsafe_h)
    # noinspection RubyYardReturnMatch
    p.symbolize_keys
  end

  # The meaningful request URL parameters as a Hash (not including :controller
  # or :action).
  #
  # @param [ActionController::Parameters, Hash, nil] p   Default: `params`.
  #
  # @return [Hash{Symbol=>String}]
  #
  # @see #request_parameters
  # @see #IGNORED_PARAMETERS
  #
  def url_parameters(p = nil)
    request_parameters(p).except!(*IGNORED_PARAMETERS)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the value has been compressed.
  #
  # @param [String, nil] v
  #
  def compressed_value?(v)
    v.to_s.start_with?(COMPRESSION_MARKER)
  end

  # compress_value
  #
  # @param [String] v
  #
  # @return [String]
  #
  def compress_value(v)
    COMPRESSION_MARKER + Base64.strict_encode64(Zlib.deflate(v))
  end

  # decompress_value
  #
  # @param [String, nil] v
  #
  # @return [String, nil]
  #
  def decompress_value(v)
    v = Zlib.inflate(Base64.strict_decode64(v[1..-1])) if compressed_value?(v)
    v.presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get a reference to `session[section]`.
  #
  # @param [String, Symbol, nil] section
  # @param [Hash, nil]           p        Default: `params`.
  #
  # @return [Hash]
  #
  def session_section(section = nil, p = nil)
    section, p = [nil, section] if section.is_a?(Hash)
    section ||= (p || params)[:controller]&.to_s || 'all'
    session[section] = {} unless session[section].is_a?(Hash)
    session[section]
  end

end

__loading_end(__FILE__)
