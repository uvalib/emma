# app/helpers/params_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper support methods related to `params` and `session`.
#
module ParamsHelper

  include Emma::Common

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL :id term which indicates the target is the identifier of the
  # current record (depending on the context).
  #
  # @type [String]
  #
  CURRENT_ID = 'CURRENT'

  # The suffix of a URL :action term which indicates that the action is to
  # operate on the current (context-specific) value.
  #
  # @type [String]
  #
  CURRENT_ACTION_SUFFIX = '_current'

  # The suffix of a URL :action term which indicates that the action is to
  # present a menu of records.
  #
  # @type [String]
  #
  SELECT_ACTION_SUFFIX = '_select'

  # Elements of `#params` which are not actually supplied as URL parameters.
  #
  # @type [Array<Symbol>]
  #
  NON_URL_KEYS = %i[controller action format].freeze

  # Request URL parameters that are used by the system.
  #
  # @type [Array<Symbol>]
  #
  SYSTEM_PARAMS = %i[
    _method
    authenticity_token
    commit
    g-recaptcha-response
    modal
    redirect
    utf8
  ].freeze

  # Request parameters that are not relevant to the application.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_PARAMS = (NON_URL_KEYS + SYSTEM_PARAMS).uniq.freeze

  # Used as the first character of a session value that has been compressed.
  #
  # @type [String]
  #
  COMPRESSION_MARKER = "\u0007"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the action represents a menu.
  #
  # @param [Symbol, String, nil] action
  #
  def menu_action?(action)
    action.to_s.end_with?(SELECT_ACTION_SUFFIX)
  end

  # Return the base action for a value which may or may not end with a suffix
  # indicating generation of a menu.
  #
  # @param [Symbol, String] action
  #
  # @return [Symbol]
  #
  def base_action(action)
    "#{action}".tap { |result|
      result.delete_suffix!(CURRENT_ACTION_SUFFIX)
      result.delete_suffix!(SELECT_ACTION_SUFFIX)
    }.to_sym
  end

  # Return the variant of the action which indicates generation of a menu.
  #
  # @param [Symbol, String] action
  #
  # @return [Symbol]
  #
  def menu_action(action)
    if menu_action?(action)
      action.to_sym
    else
      "#{action}#{SELECT_ACTION_SUFFIX}".to_sym
    end
  end

  # Normalize a list of model identifier values.
  #
  # @param [Array<Symbol,String,Integer,Array,nil>] ids
  # @param [String,Regexp]                          separator
  #
  # @return [Array<Integer,String>]
  #
  def identifier_list(*ids, separator: /\s*,\s*/, **)
    ids = ids.flat_map { _1.is_a?(String) ? _1.strip.split(separator) : _1 }
    ids.map! { _1.is_a?(ApplicationRecord) ? _1.id : _1 }
    ids.map! { positive(_1) || _1 }.compact_blank
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
  # @param [ActionController::Parameters, Hash, nil] prm  Default: `params`.
  #
  # @return [Hash]
  #
  def request_parameters(prm = nil)
    normalize_hash(prm || try(:params) || {})
  end

  # The meaningful request URL parameters as a Hash (not including :controller
  # or :action).
  #
  # @param [ActionController::Parameters, Hash, nil] prm  Default: `params`.
  #
  # @return [Hash]
  #
  def url_parameters(prm = nil)
    request_parameters(prm).except!(*IGNORED_PARAMS)
  end

  # Request parameters without :id.
  #
  # @param [Hash] added               Added/replaced parameter values.
  #
  # @return [Hash]
  #
  def without_id(**added)
    request_parameters.except(:id).merge(added)
  end

  # Redirection parameters with full data (used to allow redirection back to a
  # form with supplied values intact).
  #
  # @param [Hash] added               Added/replaced parameter values.
  #
  # @return [Hash]
  #
  def redir_params(**added)
    request_parameters.except(*SYSTEM_PARAMS).merge(added)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get a reference to `session[section]`.
  #
  # @param [String, Symbol, nil] section
  #
  # @return [Hash]
  #
  def session_section(section = nil)
    section = (section || request_parameters[:controller] || :all).to_s
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

  # Indicate whether this is the session's first operation since the last
  # reboot.
  #
  def first_operation?
    last_operation_time < BOOT_TIME.to_i
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
  # @param [any, nil] v   Symbol,String,Hash,Module; def: `params[:controller]`
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
      v.try(:controller_name)
    end
  end

  # Translate an item into the URL parameter for the controller with which it
  # is associated.
  #
  # @param [any, nil] v   Symbol, String, Hash; def: `params[:action]`.
  #
  # @return [String]
  # @return [nil]
  #
  def action_to_name(v = nil)
    v ||= request_parameters
    v = v[:action] || v['action'] if v.is_a?(Hash)
    if v.is_a?(String) || v.is_a?(Symbol)
      v.to_s.strip.underscore
    else
      v.try(:action_name)
    end
  end

  # Translate into the URL parameters for the associated controller and action.
  #
  # @param [Symbol,String,Hash,Module,*] ctrlr    Def: `params[:controller]`
  # @param [Symbol,String,*]             action   Def: `params[:action]`
  #
  # @return [Array(String,String)]
  # @return [Array(String,nil)]
  # @return [Array(nil,String)]
  # @return [Array(nil,nil)]
  #
  #--
  # === Variations
  #++
  #
  # @overload ctrlr_action_to_names
  #   Get :controller and :action from `#params`.
  #   @return [Array(String,String)]
  #
  # @overload ctrlr_action_to_names(hash)
  #   Extract :controller and/or :action from *hash*.
  #   @param [Hash] hash
  #   @return [Array(String,String)]
  #   @return [Array(String,nil)]
  #   @return [Array(nil,String)]
  #   @return [Array(nil,nil)]
  #
  # @overload ctrlr_action_to_names(ctrlr)
  #   @param [Symbol, String, Module] ctrlr
  #   @return [Array(String,nil)]
  #
  # @overload ctrlr_action_to_names(ctrlr, action)
  #   @param [any, nil]       ctrlr   Symbol, String, Hash, Module
  #   @param [Symbol, String] action
  #   @return [Array(String,String)]
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
