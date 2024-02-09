# app/helpers/layout_helper/overlay.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the 'overlays' container.
#
module LayoutHelper::Overlay

  include LayoutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # HTML elements common to all overlays.
  #
  # @type [Hash]
  #
  OVERLAY_ATTRIBUTES = {
    role:                         'none',
    'aria-hidden':                true,
    'data-turbolinks-permanent':  true,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The element holding all overlays.
  #
  # @param [Array,String] overlays    Default: #search_in_progress.
  # @param [String]       css         Characteristic CSS class/selector.
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def overlay_container(*overlays, css: '.overlays', **opt)
    prepend_css!(opt, css).reverse_merge!(OVERLAY_ATTRIBUTES)
    overlays << search_in_progress if overlays.empty?
    html_div(*overlays, **opt)
  end

  # The overlay used to indicate that a long-running action is taking place.
  #
  # @param [String, nil] content      Default: .search-in-progress background.
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_in_progress(content = nil, css: '.search-in-progress', **opt)
    prepend_css!(opt, css).reverse_merge!(OVERLAY_ATTRIBUTES)
    html_div(**opt) { html_div(content, class: 'content') }
  end

end

__loading_end(__FILE__)
