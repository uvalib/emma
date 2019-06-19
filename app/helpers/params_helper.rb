# app/helpers/params_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Time and time span methods.
#
module ParamsHelper

  def self.included(base)
    __included(base, '[ParamsHelper]')
  end

  TRUE_VALUES  = %w(1 yes true).freeze
  FALSE_VALUES = %w(0 no false).freeze

  # Request parameters that are not relevant to the application.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_PARAMETERS = %i[controller action]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item represents a true value.
  #
  # @param [String, Boolean] value
  #
  def true?(value)
    TRUE_VALUES.include?(value.to_s.strip.downcase)
  end

  # Indicate whether the item represents a true value.
  #
  # @param [String, Boolean] value
  #
  def false?(value)
    FALSE_VALUES.include?(value.to_s.strip.downcase)
  end

  # Generate a URL or partial path.
  #
  # @param [String]    path
  # @param [Hash, nil] opt
  #
  # @return [String]
  #
  def make_path(path, **opt)
    result = path.to_s.dup
    if opt.present?
      result << (result.include?('?') ? '&' : '?')
      result << opt.to_param
    end
    result
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

  # Return URL parameters as a hash.
  #
  # @param [ActionController::Parameters, Hash] p   Default: `#params`.
  #
  # @return [Hash{Symbol=>String}]
  #
  # @see #IGNORED_PARAMETERS
  #
  def url_parameters(p = nil)
    p ||= respond_to?(:params) ? params : {}
    p = p.except(*IGNORED_PARAMETERS)
    p = p.to_unsafe_h if p.respond_to?(:to_unsafe_h)
    p.symbolize_keys
  end

end

__loading_end(__FILE__)
