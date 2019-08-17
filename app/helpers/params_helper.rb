# app/helpers/params_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods related to `#params` and `#session`.
#
module ParamsHelper

  def self.included(base)
    __included(base, '[ParamsHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Request parameters that are not relevant to the application.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_PARAMETERS = %i[controller action utf8 commit]

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
  # @param [ActionController::Parameters, Hash] p   Default: `#params`.
  #
  # @return [Hash{Symbol=>String}]
  #
  def request_parameters(p = nil)
    p ||= respond_to?(:params) ? params : {}
    p = p.to_unsafe_h if p.respond_to?(:to_unsafe_h)
    # noinspection RubyYardReturnMatch
    p.symbolize_keys
  end

  # The meaningful request URL parameters as a Hash (not including :controller
  # or :action).
  #
  # @param [ActionController::Parameters, Hash, nil] p   Default: `#params`.
  #
  # @return [Hash{Symbol=>String}]
  #
  # @see #request_parameters
  # @see #IGNORED_PARAMETERS
  #
  def url_parameters(p = nil)
    request_parameters(p).except(*IGNORED_PARAMETERS)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get a reference to `session[section]`.
  #
  # @param [String, Symbol, nil] section
  # @param [Hash, nil]           p        Default: `#params`.
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
