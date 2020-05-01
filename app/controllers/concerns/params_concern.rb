# app/controllers/concerns/params_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Facilities for working with received URL parameters.
#
# @see ParamsHelper
#
module ParamsConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'ParamsConcern')

    # Needed for #set_sort_params.
    include LayoutHelper::SearchControls

    # Non-functional hints for RubyMine.
    # :nocov:
    unless ONLY_FOR_DOCUMENTATION
      include AbstractController::Callbacks::ClassMethods
      include ParamsConcern
    end
    # :nocov:

    # =========================================================================
    # :section: Callbacks
    # =========================================================================

    before_action :set_current_path,     unless: :request_xhr?
    before_action :set_origin,           only:   %i[index]
    before_action :resolve_sort,         only:   %i[index]
    before_action :initialize_menus,     except: %i[index] # TODO: keep?
    before_action :cleanup_parameters

    append_before_action :conditional_redirect

  end

  include Emma::Common
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters related to search menu settings.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_KEYS = %i[keyword sort limit language]

  # URL parameters related to search sort menu settings.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_SORT_KEYS = %i[sortOrder direction]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Accumulator for the URL parameters to be used for redirection after
  # "before" actions have been run.
  #
  # @param [String, Hash] url
  #
  # @return [true]                    Default setting which will cause the
  #                                     final state of `params` to be used by
  #                                     #conditional_redirect.
  # @return [false]                   Setting by an intermediate filter
  # @return [String]
  # @return [Hash]
  #
  # @see #conditional_redirect
  #
  def will_redirect(url = nil)
    if url.present?
      session['redirect'] = url
    else
      session['redirect'] ||= true
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # The current path stored in the session cookie.
  #
  # @return [String, nil]
  #
  def get_current_path
    decompress_value(session['current_path']).tap do |path|
      session.delete('current_path') if path.blank?
    end
  end

  # Set current page used by Devise as the redirect target after sign-in.
  #
  # @return [void]
  #
  def set_current_path
    return if !request.get? || request.xhr? || modal?
    # noinspection RubyCaseWithoutElseBlockInspection
    case params[:controller].to_s.downcase
      when 'api'        then return if params[:action] == 'image'
      when 'artifact'   then return if params[:action] == 'show'
      when %r{^devise/} then return
      when %r{^user/}   then return
    end
    if request.path == root_path
      session.delete('current_path')
    else
      prms = url_parameters.except(:id)
      path = make_path(request.path, prms)
      comp = compress_value(path)
      session['current_path'] = (path.size <= comp.size) ? path : comp
    end
  end

  # Visiting the index page of a controller sets the session origin.
  #
  # This allows pages to behave differently depending on whether they are
  # reached from a search, or from somewhere else.
  #
  # @return [void]
  #
  def set_origin
    return unless params[:action] == 'index'
    origin = (params[:controller].presence unless request.path == root_path)
    session['origin'] = origin || 'root'
  end

  # Resolve the menu-generated :sort selection into the appropriate pair of
  # :sortOrder and :direction parameters.
  #
  # @return [void]
  #
  # @see LayoutHelper#sort_menu
  #
  def resolve_sort
    changed = false

    if self.class == SearchController

      # Relevance is the default sort but the Unified Search API doesn't
      # actually accept it as a sort type.
      if params[:sort].to_s.casecmp('relevance').zero?
        params.delete(:sort)
        changed = true
      end

    else

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

    end

    will_redirect if changed
  end

  # Load `params` with values last set when searching.
  #
  # @return [void]
  #
  def initialize_menus
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
    path = session.delete('redirect')
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
    reverse = is_reverse?(sort_value)
    params[:sortOrder] = ascending_sort(sort_value)
    params[:direction] = reverse ? 'desc' : 'asc'
  end

end

__loading_end(__FILE__)
