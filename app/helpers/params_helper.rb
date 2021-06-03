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

  # Indicate whether the current request is an HTTP GET.
  #
  def request_get?
    request.get?
  end

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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Translate an item into the URL parameter for the controller with which it
  # is associated.
  #
  # @param [Symbol, String, Hash, Module, *] v  Def: `params[:controller]`.
  #
  # @return [String]
  # @return [nil]
  #
  def controller_to_name(v = nil)
    v ||= request_parameters
    v = v[:controller] || v['controller'] if v.is_a?(Hash)
    # noinspection RubyYardReturnMatch, RubyCaseWithoutElseBlockInspection
    case v
      when String, Symbol
        v.to_s.strip.underscore.delete_suffix('_controller')
      when ApplicationController
        v.controller_name
      when Class
        v.controller_name if v.respond_to?(:controller_name)
    end
  end

  # Translate an item into the URL parameter for the controller with which it
  # is associated.
  #
  # @param [Symbol, String, Hash, *] v  Def: `params[:controller]`.
  #
  # @return [String]
  # @return [nil]
  #
  def action_to_name(v = nil)
    v ||= request_parameters
    v = v[:action] || v['action'] if v.is_a?(Hash)
    # noinspection RubyYardReturnMatch, RubyCaseWithoutElseBlockInspection
    case v
      when String, Symbol        then v.to_s.strip.underscore
      when ApplicationController then v.action_name
    end
  end

  # Translate into the URL parameters for the associated controller and action.
  #
  # @param [Symbol, String, Hash, Module, *] ctrlr   Def: `params[:controller]`
  # @param [Symbol, String, nil]             action  Def: `params[:action]`
  #
  # @return [(*,*)]
  #
  # == Variations
  #
  # @overload ctrlr_action_to_names
  #   Get :controller and :action from `#params`.
  #   @return [(String,String)]
  #
  # @overload ctrlr_action_to_names(hash)
  #   Extract :controller and/or :action from *hash*.
  #   @param [Hash] hash
  #   @return [(String,String)]
  #   @return [(String,nil)]
  #   @return [(nil,String)]
  #   @return [(nil,nil)]
  #
  # @overload ctrlr_action_to_names(ctrlr)
  #   @param [Symbol, String, Module] ctrlr
  #   @return [(String,nil)]
  #
  # @overload ctrlr_action_to_names(ctrlr, action)
  #   @param [Symbol, String, Hash, Module, *] ctrlr
  #   @param [Symbol, String]                  action
  #   @return [(String,String)]
  #
  def ctrlr_action_to_names(ctrlr = nil, action = nil)
    ctrlr  = request_parameters unless ctrlr || action
    result = []
    if action
      result << controller_to_name(ctrlr)
      result << action_to_name(action)
    elsif ctrlr.is_a?(Hash)
      result << controller_to_name(ctrlr)
      result << action_to_name(ctrlr)
    else
      result << controller_to_name(ctrlr)
      result << nil
    end
  end

end

__loading_end(__FILE__)
