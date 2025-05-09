# app/controllers/concerns/params_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller callbacks for working with received URL parameters.
#
# @see ParamsHelper
#
module ParamsConcern

  extend ActiveSupport::Concern

  include Emma::Common

  include DevHelper
  include ParamsHelper
  include SearchTermsHelper

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include LayoutHelper::SearchFilters
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Controllers with their own independent on-screen debugging facilities.
  #
  # On these pages, the "&debug=..." URL parameter is treated as if it was
  # "&app.(ctrlr).debug=...".
  #
  # @type [Array<Symbol>]
  #
  SPECIAL_DEBUG_CONTROLLERS = %i[search].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether a parameter value matches #CURRENT_ID.
  #
  # @param [any, nil] id
  #
  def current_id?(id)
    CURRENT_ID.casecmp?(id)
  end

  # The identifier of the current model instance which #CURRENT_ID represents.
  #
  # This is only applicable to session-based models like User and
  # (by extension) Org.
  #
  # @return [Integer, String, nil]
  #
  def current_id
    not_applicable
  end

  # URL parameters associated with model record(s).
  #
  # @return [Array<Symbol>]
  #
  def id_param_keys
    %i[selected id]
  end

  # ===========================================================================
  # :section: ParamsHelper overrides
  # ===========================================================================

  public

  # Normalize a list of model identifier values.
  #
  # Instances of #CURRENT_ID are replaced with `#current_id`.
  #
  # @param [Array<Symbol,String,Integer,Array,nil>] ids
  # @param [Hash]                                   opt   To super
  #
  # @return [Array<Integer,String>]
  #
  def identifier_list(*ids, **opt)
    cid = current_id.presence
    ids = params.values_at(*id_param_keys) if ids.blank?
    super.tap do |result|
      result.map! { CURRENT_ID.casecmp?(_1) ? cid : _1 } if cid
    end
  end

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
    request.xhr?
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
    request.referrer.to_s.start_with?(root_url)
  end

  # Indicate whether the current request originates from an application page.
  #
  def same_request?
    [request.url, request.fullpath].include?(request.referrer)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Accumulator for the URL parameters to be used for redirection after
  # "before" actions have been run.
  #
  # @param [String, Hash] url
  #
  # @return [TrueClass]               Default setting which will cause the
  #                                     final state of `params` to be used by
  #                                     #conditional_redirect.
  # @return [FalseClass]              Setting by an intermediate filter
  # @return [String]                  Redirection URL.
  # @return [Hash]                    Redirection path components.
  #
  # @see #conditional_redirect
  #
  def will_redirect(url = nil)
    if url.present?
      session['app.redirect'] = url
    else
      session['app.redirect'] ||= true
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Called to ensure that a fresh copy is requested each time.
  #
  def no_cache
    expires_now
  end

  # Called from non-SearchController pages to ensure that the search defined in
  # the page header performs the intended operation on the SearchController and
  # not the current controller.
  #
  def search_redirect
    return if SEARCH_CONTROLLERS.include?(params[:controller]&.to_sym)
    query = request_parameters
    return if query.slice(:q, :title, :creator, :identifier).blank?
    redirect_to query.merge!(controller: DEFAULT_SEARCH_CONTROLLER)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The current path stored in the session cookie.
  #
  # @return [String]                  Value of `session['app.current_path']`.
  # @return [nil]                     No 'app.current_path' found.
  #
  # @return [String]
  #
  def get_current_path
    decompress_value(session['app.current_path']).tap do |path|
      session.delete('app.current_path') if path.blank?
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Set current page used by Devise as the redirect target after sign-in.
  #
  # @return [void]
  #
  def set_current_path
    case params.values_at(:controller, :action).join('/')
      when 'search/image' then return
      when %r{^devise/}   then return
      when %r{^user/}     then return
    end
    if request.path == root_path
      session.delete('app.current_path')
    else
      prms = url_parameters.except(:id)
      path = make_path(request.path, **prms)
      comp = compress_value(path)
      session['app.current_path'] = (path.size <= comp.size) ? path : comp
    end
    session['app.time'] = DateTime.now
  end

  # Set session on-screen debugging:
  #
  # URL parameters:
  # - 'debug'               manage debugging relative to the current controller
  # - 'app.debug'           general debugging
  # - 'app.(ctrlr).debug'   manage debugging for the indicated controller
  #
  # Session keys:
  # - session['app.debug']          general debugging display
  # - session['app.search.debug']   search debugging only
  #
  # @return [void]
  #
  def set_debug
    ctrlr = params[:controller]&.to_sym
    ctrlr = nil unless SPECIAL_DEBUG_CONTROLLERS.include?(ctrlr)
    debug_parameters =
      url_parameters.keys.map { |k|
        case k.to_s
          when 'debug'                 then context = ctrlr
          when 'app.debug'             then context = nil
          when /^app\.([^.]+)\.debug$/ then context = $1
          else                              next
        end
        [context, params.delete(k)]
      }.compact.to_h
    return if debug_parameters.empty?

    on  = true
    off = application_deployed? && !dev_client? && :delete

    debug_parameters.each_pair do |context, debug|
      key   = context ? "app.#{context}.debug" : 'app.debug'
      log   = "#{__method__}: #{key}=#{debug.inspect} -> %s"
      state =
        case
          when debug.to_s.casecmp?('reset') then Log.info(log % 'RESET') || off
          when false?(debug)                then Log.info(log % 'OFF')   || off
          when true?(debug)                 then Log.info(log % 'ON')    || on
          else                                   Log.warn(log % 'UNEXPECTED')
        end
      case state
        when true, false then session[key] = state
        when :delete     then session.delete(key)
        else                  # no change
      end
    end

    will_redirect
  end

  # Set suppression of developer-only controls.
  #
  # URL parameters:
  # - 'dev_controls'
  # - 'app.dev_controls'
  #
  # Session keys:
  # - session['app.dev_controls']
  #
  # @return [void]
  #
  def set_dev_controls
    session_key = 'app.dev_controls'
    url_keys    = %i[dev_controls app.dev_controls]
    parameters  = url_keys.map { [_1, params.delete(_1)] }.to_h.compact
    value       = parameters.values.first
    if true?(value)
      session.delete(session_key)
    elsif false?(value)
      session[session_key] = false
    end
    will_redirect if parameters.present?
  end

  # Visiting the index page of a controller sets the session origin.
  #
  # This allows pages to behave differently depending on whether they are
  # reached from a search, or from somewhere else.
  #
  # @return [void]
  #
  def set_origin
    return unless route_request? && (params[:action] == 'index')
    origin = (params[:controller].presence unless request.path == root_path)
    session['app.origin'] = origin || 'root'
  end

  # Save `params` related to federated index search.
  #
  # @return [void]
  #
  # @see LayoutHelper#sort_menu
  #
  def save_search_menus
    return if %w[search upload].include?(params[:controller].to_s.downcase)
    ss = session_section
    SEARCH_KEYS.each do |key|
      ss_key = key.to_s
      if params[key].present?
        ss[ss_key] = params[key]
      else
        ss.delete(ss_key)
      end
    end
  end

  # Load `params` with values last set for federated index search.
  #
  # @return [void]
  #
  def init_search_menus
    return if %w[search upload].include?(params[:controller].to_s.downcase)
    ss = session_section
    SEARCH_KEYS.each do |key|
      ss_value = ss[key.to_s]
      params[key] = ss_value if ss_value.present?
    end
  end

  # Clean up URL parameters and redirect.
  #
  # This eliminates "noise" parameters injected by the advanced search forms
  # and other situations where empty or unneeded parameters accumulate.
  #
  # === Usage Notes
  # If a callback relies on the :commit parameter, it must be run before this
  # callback.
  #
  def cleanup_parameters
    original_count = params.keys.size

    # Eliminate "noise" parameters.
    params.delete_if { _1.blank? || _2.blank? }
    %w[utf8 commit].each { params.delete(_1) }

    # If parameters were removed, redirect to the corrected URL.
    will_redirect unless params.keys.size == original_count
  end

  # To be run after all before_actions that modify params and require a
  # redirect in order to normalize the URL.
  #
  # @return [void]
  #
  # @see #will_redirect
  #
  def conditional_redirect
    return unless request.get?
    path = session.delete('app.redirect')
    path = request_parameters if path.is_a?(TrueClass)
    redirect_to(path) if path.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    # Non-functional hints for RubyMine type checking.
    # :nocov:
    unless ONLY_FOR_DOCUMENTATION
      include AbstractController::Callbacks::ClassMethods
      include ParamsConcern
    end
    # :nocov:

    # =========================================================================
    # :section: Callbacks
    # =========================================================================

    if respond_to?(:before_action)

      before_action :search_redirect
      before_action :set_current_path,     if:     :route_request?
      before_action :set_dev_controls,     if:     :route_request?
      before_action :set_debug,            if:     :route_request?
      before_action :set_origin,           only:   %i[index]
      before_action :save_search_menus,    only:   %i[index]
      before_action :init_search_menus,    except: %i[index] # TODO: keep?
      before_action :cleanup_parameters,   if:     :route_request?

      append_before_action :conditional_redirect

    end

  end

end

__loading_end(__FILE__)
