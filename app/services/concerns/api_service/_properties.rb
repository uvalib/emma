# app/services/concerns/api_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Properties
#
module ApiService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Control generation of extra debugging output for browser downloads.
  #
  # @type [Boolean]
  #
  DEBUG_DOWNLOAD = true?(ENV_VAR['DEBUG_DOWNLOAD'])

  # Control whether information requests are ever cached. # TODO: ???
  #
  # @type [Boolean]
  #
  CACHING = false

  # Control whether parameter validation errors cause a RuntimeError.
  #
  # @type [Boolean]
  #
  RAISE_ON_INVALID_PARAMS = Rails.env.test?

  # Maximum length of redirection chain.
  #
  # @type [Integer]
  #
  MAX_REDIRECTS = 2

  # Options consumed by #api (and not passed on as URL query options).
  #
  # @type [Array<Symbol>]
  #
  SERVICE_OPT = %i[fatal no_exception no_redirect].freeze

  # Original request parameters which should not be passed on to the API.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_PARAMETERS = [*ParamsHelper::IGNORED_PARAMS, :offset].freeze

  # HTTP methods used by the API.
  #
  # @type [Array<Symbol>]
  #
  HTTP_METHODS =
    %i[GET PUT POST DELETE].map { [_1, _1.downcase] }.flatten.freeze

  # Engine key values which indicate that the engine should be returned to
  # normal.
  #
  # @type [Array<Symbol>]
  #
  RESET_KEYS = %i[normal default reset].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of the service for logging.
  #
  # @return [String]
  #
  def service_name(...)
    @service_name ||= ApiService.name_for(try(:name) || self.class.try(:name))
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The service identified by the given value.
  #
  # @param [any, nil] target
  #
  # @return [String]
  #
  def name_for(target)
    target.to_s.demodulize.underscore.delete_suffix('_service')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for the API service.
  #
  # @return [Hash]
  #
  def configuration
    config_section(:service, service_name)
  end

  # The URL for the API connection.
  #
  # @return [String]
  #
  def base_url
    @base_url ||= default_engine_url
  end

  # The URL for the API connection as a URI.
  #
  # @return [URI::Generic]
  #
  def base_uri
    @base_uri ||= URI.parse(base_url)
  end

  # API key (if applicable).
  #
  # @return [String, nil]
  #
  def api_key
    configuration[:api_key]
  end

  # API version (if applicable).
  #
  # @return [String, nil]
  #
  def api_version
    configuration[:api_version]
  end

  # API user account (if applicable).
  #
  # @return [String, nil]
  #
  def api_user
    configuration[:api_user]
  end

  # API user account password (if applicable).
  #
  # @return [String, nil]
  #
  # @note Currently unused.
  # :nocov:
  def api_password
    configuration[:api_password]
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Valid service endpoint URLs.
  #
  # For a given service configuration, :endpoint may be a simple string value
  # (which becomes associated with #default_engine_key) or a Hash of engine
  # names and their respective values.
  #
  # If the string value is not a URL, it is interpreted as the name of
  # environment variable which holds the URL.  In configuration, this can be
  # represented as the environment variable name with or without "ENV":
  #
  # - '"ENV[SERVICE_SEARCH_PRODUCTION]"'
  # - 'ENV[SERVICE_SEARCH_PRODUCTION]'
  # - '"SERVICE_SEARCH_PRODUCTION"'
  # - 'SERVICE_SEARCH_PRODUCTION'
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see "en.emma.service.*.endpoint"
  #
  def engines
    meth = "#{service_name}.#{__method__}"
    prop = configuration[:endpoint]
    prop = { default_engine_key => prop } unless prop.is_a?(Hash)
    prop.map { |engine, host|
      log = ->(msg) { Log.warn { "#{meth}: #{engine}: #{msg}" } }
      next log.('no :endpoint given') if host.blank?
      unless host.start_with?('http')
        var  = host.split(/\s*[\[\]'"]\s*/).compact_blank.last
        next log.("invalid: #{host.inspect}") if var.blank?
        host = ENV_VAR[var] || Object.safe_const_get(var)
        next log.("ENV_VAR[#{var}]: not present") if host.blank?
      end
      [engine, host]
    }.compact.to_h.tap { |result|
      result[:default] ||= result[default_engine_key]
    }
  end

  # Default service endpoint for this deployment.
  #
  # @return [String]
  #
  def default_engine_url
    engines[default_engine_key]
  end

  # The default service engine key.
  #
  # @return [Symbol]
  #
  def default_engine_key
    :default
  end

  # engine_url
  #
  # @param [any, nil] value           Engine name or URL (String, Symbol)
  #
  # @return [String, nil]
  #
  def engine_url(value)
    if value.is_a?(String) && value.include?('/')
      value if engines.any? { |_, url| value.start_with?(url) }
    elsif RESET_KEYS.include?((key = value.to_s.downcase.to_sym))
      default_engine_url
    else
      engines[key]
    end
  end

  # engine_key
  #
  # @param [Symbol, String] value   Engine name or URL.
  #
  # @return [Symbol, nil]
  #
  def engine_key(value)
    if value.is_a?(String) && value.include?('/')
      engines.find { |key, url| break key if value == url }
    elsif engines.include?((key = value.to_s.downcase.to_sym))
      key
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Maximum length of redirection chain.
  #
  # @type [Integer]
  #
  def max_redirects
    configuration[:max_redirects] || MAX_REDIRECTS
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
