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
  SCROLL_TOP = {
    type:    'button',
    class:   'scroll-to-top',
    label:   UP_TRIANGLE, # TODO: I18n
    tooltip: 'Go back to the top of the page', # TODO: I18n
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Modify the provided CSS options to indicate that the element is defined as
  # the target for the scroll-to-top button.
  #
  # @param [Hash] opt                 CSS options hash to modify.
  #
  # @return [Hash]                    The modified *opt*.
  #
  def scroll_to_top_target!(opt)
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
    opt   = merge_html_options(SCROLL_TOP, opt, { class: 'hidden' })
    label = opt.delete(:label)
    tip   = opt.delete(:tooltip)
    opt[:title] = tip || opt[:title]
    opt[:type]  = 'button'
    button_tag(label, opt)
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
