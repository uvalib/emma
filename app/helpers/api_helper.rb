# app/helpers/api_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiHelper
#
# @see ApiController
# @see app/views/api
#
module ApiHelper

  def self.included(base)
    __included(base, '[ApiHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Invoke an API method.
  #
  # @param [Symbol]    method
  # @param [String]    path
  # @param [Hash, nil] opt
  #
  # @return [Hash]
  #
  def api_method(method, path, **opt)
    type   = method
    method = "api_#{method}".downcase.to_sym
    result = ApiService.instance.send(method, path, opt)
    if result.is_a?(Hash) && result[:invalid]
      result
    else
      {
        method:  type.to_s.upcase,
        request: make_path(path, opt),
        result:  result
      }
    end
  end

  # Generate a URL or partial path.
  #
  # @param [String]    path
  # @param [Hash, nil] opt
  #
  # @return [Hash]
  #
  def make_path(path, **opt)
    result = path.to_s.dup
    if opt.present?
      result << (result.include?('?') ? '&' : '?')
      result << opt.to_param
    end
    result
  end

end

__loading_end(__FILE__)
