# app/helpers/params_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper support methods related to `params` and `session`.
#
module ParamsHelper

  include Emma::Common

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
  # @param [ActionController::Parameters, Hash, nil] p   Default: `params`.
  #
  # @return [Integer]
  #
  def request_parameter_count(p = nil)
    # noinspection RailsParamDefResolve
    prm = p || try(:params) || {}
    prm.keys.size
  end

  # All request parameters (including :controller and :action) as a Hash.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Default: `params`.
  #
  # @return [Hash{Symbol=>String}]
  #
  def request_parameters(p = nil)
    # noinspection RailsParamDefResolve
    normalize_hash(p || try(:params))
  end

  # The meaningful request URL parameters as a Hash (not including :controller
  # or :action).
  #
  # @param [ActionController::Parameters, Hash, nil] prm  Default: `params`.
  #
  # @return [Hash{Symbol=>String}]
  #
  # @see #request_parameters
  # @see #IGNORED_PARAMETERS
  #
  def url_parameters(prm = nil)
    request_parameters(prm).except!(*IGNORED_PARAMETERS)
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
    section = (section || request_parameters(p)[:controller] || :all).to_s
    session[section] = {} unless session[section].is_a?(Hash)
    session[section]
  end

  # Information about the last operation performed in this session.
  #
  # @return [Hash]
  #
  def last_operation
    session_section('app.last_op')
  end

  # Full URL of the last operation performed in this session.
  #
  # @return [String, nil]
  #
  def last_operation_path
    last_operation['path']
  end

  # Time of the last operation performed in this session.
  #
  # @return [Integer]
  #
  def last_operation_time
    last_operation['time'].to_i
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
  # @param [String, nil] v
  #
  # @return [String]
  #
  def compress_value(v)
    COMPRESSION_MARKER + Base64.strict_encode64(Zlib.deflate(v || ''))
  end

  # decompress_value
  #
  # @param [String, nil] v
  #
  # @return [String, nil]
  #
  def decompress_value(v)
    v = Zlib.inflate(Base64.strict_decode64(v[1..])) if compressed_value?(v)
    v.presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Translate an item into the URL parameter for the controller with which it
  # is associated.
  #
  # @param [Symbol, String, Hash, Module, Any] v  Def: `params[:controller]`.
  #
  # @return [String]
  # @return [nil]
  #
  def controller_to_name(v = nil)
    v ||= request_parameters
    v = v[:controller] || v['controller'] if v.is_a?(Hash)
    if v.is_a?(String) || v.is_a?(Symbol)
      v.to_s.strip.underscore.delete_suffix('_controller')
    else
      # noinspection RailsParamDefResolve
      v.try(:controller_name)
    end
  end

  # Translate an item into the URL parameter for the controller with which it
  # is associated.
  #
  # @param [Symbol, String, Hash, Any] v  Def: `params[:action]`.
  #
  # @return [String]
  # @return [nil]
  #
  def action_to_name(v = nil)
    v ||= request_parameters
    v = v[:action] || v['action'] if v.is_a?(Hash)
    if v.is_a?(String) || v.is_a?(Symbol)
      # noinspection RubyMismatchedReturnType
      v.to_s.strip.underscore
    else
      # noinspection RailsParamDefResolve
      v.try(:action_name)
    end
  end

  # Translate into the URL parameters for the associated controller and action.
  #
  # @param [Symbol,String,Hash,Module,Any] ctrlr    Def: `params[:controller]`
  # @param [Symbol,String,nil]             action   Def: `params[:action]`
  #
  # @return [Array<(Any,Any)>]
  #
  #--
  # == Variations
  #++
  #
  # @overload ctrlr_action_to_names
  #   Get :controller and :action from `#params`.
  #   @return [Array<(String,String)>]
  #
  # @overload ctrlr_action_to_names(hash)
  #   Extract :controller and/or :action from *hash*.
  #   @param [Hash] hash
  #   @return [Array<(String,String)>]
  #   @return [Array<(String,nil)>]
  #   @return [Array<(nil,String)>]
  #   @return [Array<(nil,nil)>]
  #
  # @overload ctrlr_action_to_names(ctrlr)
  #   @param [Symbol, String, Module] ctrlr
  #   @return [Array<(String,nil)>]
  #
  # @overload ctrlr_action_to_names(ctrlr, action)
  #   @param [Symbol, String, Hash, Module, Any] ctrlr
  #   @param [Symbol, String]                    action
  #   @return [Array<(String,String)>]
  #
  def ctrlr_action_to_names(ctrlr = nil, action = nil)
    ctrlr  = request_parameters unless ctrlr || action
    result = []
    # noinspection RubyMismatchedArgumentType
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
