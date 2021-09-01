# app/services/concerns/api_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/https'
require 'faraday'

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
  # == Usage Notes
  # Compare with BsAllowsType#values.
  #
  HTTP_METHODS =
    %w(GET PUT POST DELETE)
      .map { |w| [w.to_sym, w.downcase.to_sym] }.flatten.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of the service for logging.
  #
  # @return [String]
  #
  def service_name(*)
    # noinspection RailsParamDefResolve
    @service_name ||=
      (try(:name) || self.class.name).underscore.delete_suffix('_service')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL for the API connection.
  #
  # @return [String]
  #
  def base_url
    @base_url ||= not_implemented 'must be defined by the subclass'
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
    not_implemented 'must be defined by the subclass'
  end

  # API version (if applicable).
  #
  # @return [String, nil]
  #
  def api_version
    not_implemented 'must be defined by the subclass'
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
    MAX_REDIRECTS
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
