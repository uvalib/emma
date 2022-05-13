# app/services/concerns/api_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Properties
#
module ApiService::Properties

  include I18nHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  SERVICE_OPTIONS = %i[no_raise no_exception no_redirect].freeze

  # Original request parameters which should not be passed on to the API.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_PARAMETERS = (ParamsHelper::IGNORED_PARAMETERS + %i[offset]).freeze

  # HTTP methods used by the API.
  #
  # @type [Array<Symbol>]
  #
  # == Implementation Notes
  # Compare with BsAllowsType#values.
  #
  HTTP_METHODS =
    %w(GET PUT POST DELETE)
      .map { |w| [w.to_sym, w.downcase.to_sym] }.flatten.deep_freeze

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
    # noinspection RailsParamDefResolve
    @service_name ||= ApiService.name_for(try(:name) || self.class.try(:name))
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The service identified by the given value.
  #
  # @param [Any] target
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
  # @type [Hash{Symbol=>Any}]
  #
  def configuration
    i18n_erb("emma.service.#{service_name}", default: {})
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
  def api_password
    configuration[:api_password]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Valid service endpoint URLs.
  #
  # @type [Hash{Symbol=>String}]
  #
  def engines
    value = configuration[:endpoint]
    value.is_a?(Hash) ? value : { default_engine_key => value }
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
  # @param [Symbol, String] value   Engine name or URL.
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
      # noinspection RubyMismatchedReturnType
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
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
