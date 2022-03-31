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
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include LayoutHelper::SearchFilters
    # :nocov:
  end

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
  SPECIAL_DEBUG_CONTROLLERS = %i[search]

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
  # @see #SEARCH_CONTROLLERS
  # @see #DEFAULT_SEARCH_CONTROLLER
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
    # noinspection RubyCaseWithoutElseBlockInspection
    case params[:controller].to_s.downcase
      when 'artifact'   then return if params[:action] == 'show'
      when 'bs_api'     then return if params[:action] == 'image'
      when %r{^devise/} then return
      when %r{^user/}   then return
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
        if debug.to_s.casecmp?('reset') then Log.info(log % 'RESET') || off
        elsif false?(debug)             then Log.info(log % 'OFF')   || off
        elsif true?(debug)              then Log.info(log % 'ON')    || on
        else                                 Log.warn(log % 'UNEXPECTED')
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
    parameters  = url_keys.map { |k| [k, params.delete(k)] }.to_h.compact
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

  # Resolve the menu-generated :sort selection into the appropriate pair of
  # :sortOrder and :direction parameters.
  #
  # @return [void]
  #
  # @see LayoutHelper#sort_menu
  #
  def resolve_sort
    return if %w(search upload).include?(params[:controller].to_s.downcase)

    changed = false

    # Remember current search parameters.
    ss   = session_section
    keys = SEARCH_KEYS
    keys += SEARCH_SORT_KEYS if params[:sort].blank?
    keys.each do |key|
      ss_key = key.to_s
      if params[key].present?
        ss[ss_key] = params[key]
      else
        ss.delete(ss_key)
      end
    end

    # Process the menu-generated :sort parameter.
    if (sort = params.delete(:sort))
      set_sort_params(sort)
      changed = true
    end

    will_redirect if changed
  end

  # Load `params` with values last set when searching.
  #
  # @return [void]
  #
  def initialize_menus
    return if %w(search upload).include?(params[:controller].to_s.downcase)
    ss = session_section
    SEARCH_KEYS.each do |key|
      ss_value = ss[key.to_s]
      if ss_value.present?
        if key == :sort
          set_sort_params(ss_value)
        else
          params[key] = ss_value
        end
      elsif key == :sort
        SEARCH_SORT_KEYS.each do |k|
          v = ss[k.to_s]
          params[k] = v if v.present?
        end
      end
    end
  end

  # Clean up URL parameters and redirect.
  #
  # This eliminates "noise" parameters injected by the advanced search forms
  # and other situations where empty or unneeded parameters accumulate.
  #
  # == Usage Notes
  # If a callback relies on the :commit parameter, it must be run before this
  # callback.
  #
  def cleanup_parameters
    original_count = request_parameter_count

    # Eliminate "noise" parameters.
    params.delete_if { |k, v| k.blank? || v.blank? }
    %w(utf8 commit).each { |k| params.delete(k) }

    # If parameters were removed, redirect to the corrected URL.
    will_redirect unless request_parameter_count == original_count
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
  # :section: Callbacks
  # ===========================================================================

  private

  # Set :sortOrder and :direction parameters.
  #
  # @param [String] sort_value
  #
  # @return [void]
  #
  def set_sort_params(sort_value)
    no_reverse = current_menu_config(:sort).dig(:reverse, :except)
    if Array.wrap(no_reverse).include?(sort_value&.to_sym)
      params.delete(:direction)
    else
      params[:direction] = is_reverse?(sort_value) ? 'desc' : 'asc'
    end
    params[:sortOrder] = ascending_sort(sort_value)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    # Needed for #set_sort_params.
    include LayoutHelper::SearchFilters

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include AbstractController::Callbacks::ClassMethods
      include ParamsConcern
      # :nocov:
    end

    # =========================================================================
    # :section: Callbacks
    # =========================================================================

    before_action :search_redirect
    before_action :set_current_path,     if:     :route_request?
    before_action :set_dev_controls,     if:     :route_request?
    before_action :set_debug,            if:     :route_request?
    before_action :set_origin,           only:   %i[index]
    before_action :resolve_sort,         only:   %i[index]
    before_action :initialize_menus,     except: %i[index] # TODO: keep?
    before_action :cleanup_parameters

    append_before_action :conditional_redirect

  end

end

__loading_end(__FILE__)
