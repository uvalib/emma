# app/helpers/scroll_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting page scrolling.
#
module ScrollHelper

  include Emma::Unicode

  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Properties for the element which is scrolled to the top.
  #
  # @type [Hash{Symbol=>String}]
  #
  SCROLL_TARGET = {
    class: 'scroll-to-top-target'
  }.freeze

  # Default properties for the scroll-to-top button.
  #
  # @type [Hash{Symbol=>String}]
  #
  SCROLL_TOP_BUTTON = {
    type:     'button',
    class:    'scroll-to-top',
    label:    UP_TRIANGLE, # TODO: I18n
    tooltip:  'Go back to the top of the page', # TODO: I18n
  }.freeze

  # Default properties for the scroll-down-to-top button.
  #
  # @type [Hash{Symbol=>String}]
  #
  SCROLL_DOWN_BUTTON = {
    type:     'button',
    class:    'scroll-down-to-top',
    label:    DOWN_TRIANGLE, # TODO: I18n
    tooltip:  'Align with the top of the page', # TODO: I18n
  }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An empty element which will be the target for the scroll-to-top button.
  # (For use just before the intended element if it requires a gap at the top
  # of the viewport but can't have 'padding-top' set.
  #
  # @param [Hash] opt                 Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def scroll_to_top_target(**opt)
    make_scroll_to_top_target!(opt)
    opt[:role] = :none
    html_span(HTML_SPACE, opt)
  end

  # Modify the provided CSS options to indicate that the element is defined as
  # the target for the scroll-to-top button.
  #
  # @param [Hash] opt                 CSS options hash to modify.
  #
  # @return [Hash]                    The modified *opt*.
  #
  def make_scroll_to_top_target!(opt)
    append_css!(opt, SCROLL_TARGET[:class])
  end

  # Floating scroll-to-top button which starts hidden.
  #
  # @param [Hash] opt                 Passed to #button_tag except for:
  #
  # @option opt [String] :label       Override default label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/scroll.js *scrollToTop()*
  #
  def scroll_to_top_button(**opt)
    opt   = merge_html_options(SCROLL_TOP_BUTTON, opt, { class: 'hidden' })
    label = opt.delete(:label)
    tip   = opt.delete(:tooltip)
    opt[:title] = tip if tip
    html_button(label, opt)
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
