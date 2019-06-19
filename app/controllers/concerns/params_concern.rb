# app/controllers/concerns/params_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'emma/log'

# Facilities for working with received URL parameters.
#
# @see ParamsHelper
#
module ParamsConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'ParamsConcern')

    include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION

    # =========================================================================
    # :section: Callbacks
    # =========================================================================

    before_action :set_current_path
    before_action :set_origin,            only: [:index]
    before_action :resolve_sort,          only: [:index]
    before_action :cleanup_parameters
    before_action :conditional_redirect

  end

  include ParamsHelper

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
      session[:redirect] = url
    else
      session[:redirect] ||= true
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
    return if params[:controller].to_s.start_with?('devise')
    if request.path == root_path
      session.delete(:current_path)
    else
      session[:current_path] = request.path
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
    session[:origin] = origin || :root
  end

  # Resolve reverse sort into Bookshare-style parameters.
  #
  # @return [void]
  #
  # @see LayoutHelper#sort_menu
  #
  def resolve_sort
    changed = false
    if (sort = params.delete(:sort))
      session_section = params[:controller]
      ss = session[session_section] ||= {}
      ss['sort'] = sort.dup
      reverse = sort.delete_suffix!(LayoutHelper::REVERSE_SORT)
      params[:sortOrder] = sort
      params[:direction] = reverse ? 'desc' : 'asc'
      changed = true
    end
    will_redirect if changed
  end

  # Clean up URL parameters and redirect.
  #
  # This eliminates "noise" parameters injected by the advanced search forms
  # and other situations where empty or unneeded parameters accumulate.
  #
  def cleanup_parameters
    changed = false
    original_size = params.to_unsafe_h.size

    # Eliminate "noise" parameters.
    params.delete_if { |k, v| k.blank? || v.blank? }
    %w(utf8 commit).each { |k| params.delete(k) }

    # If parameters were removed, redirect to the corrected URL.
    changed ||= (params.to_unsafe_h.size != original_size)
    will_redirect if changed
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
    path = session.delete(:redirect)
    path = params.to_unsafe_h if path.is_a?(TrueClass)
    redirect_to(path) if path.present?
  end

end

__loading_end(__FILE__)
