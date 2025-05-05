# app/helpers/html_helper/symbols.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper HTML support methods.
#
module HtmlHelper::Symbols

  include HtmlHelper::Tags

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Pattern to #scan a string for HTML elements optionally preceded and
  # followed by literal text.
  #
  # @type [Regexp]
  #
  FOR_ELEMENTS = %r{
    ([^<]*)             # _1 - leading text
    (< *)               # _2 - HTML tag start
    (\w+)               # _3 - HTML tag name
    ([^>]*>)            # _4 - HTML tag end
    ([^<]*)             # _5 - HTML node contents
    (< */ *\3 *>)       # _6 - HTML tag close
    ([^<]*)             # _7 - trailing text
  }x.freeze

  # If the text has any symbols in it, hide them from screen readers.
  #
  # If so, each run of one or more symbolic characters will be wrapped in
  # `span.symbol` with 'aria-hidden' and all other runs of characters will be
  # wrapped in `span.text` (unless *text* is already ActiveSupport::SafeBuffer)
  #
  # If not, *text* will be returned HTML-ready with no `<span>`s added.
  #
  # @param [String, nil] text
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def hide_symbols(text)
    html = text.is_a?(ActiveSupport::SafeBuffer)
    text = text.to_s unless text.is_a?(String)

    return html ? text : ERB::Util.h(text) unless text.match?(SYMBOLS)

    if html && (parts = text.scan(FOR_ELEMENTS)).present?
      parts.flat_map {
        part = []
        part << _1.presence && hide_symbols(_1)           # leading text
        part << [_2, _3, _4].join                         # HTML tag
        part << _5.presence && hide_symbols(_5.html_safe) # HTML node contents
        part << _6                                        # HTML tag close
        part << _7.presence && hide_symbols(_7)           # trailing text
      }.compact.join.html_safe
    else
      text.scan(/(.*?)(#{SYMBOLS})/).flat_map { |txt, sym|
        part = []
        part << txt.presence && (html ? txt : html_span(txt, class: 'text'))
        part << symbol_icon(sym)
      }.compact.join.html_safe
    end
  end

  # ===========================================================================
  # :section: Emma::Common::FormatMethods overrides
  # ===========================================================================

  public

  # Augment Emma::Common::FormatMethods#non_breaking to hide symbols from
  # screen readers.
  #
  # @param [String, nil] text
  # @param [Boolean]     show_symbols   If *true*, don't #hide_symbols.
  # @param [Hash]        opt            To super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see Emma::Common::FormatMethods#non_breaking
  #
  def non_breaking(text, show_symbols: false, **opt)
    value = super(text, **opt)
    show_symbols ? value : hide_symbols(value)
  end

  # Augment Emma::Common::FormatMethods#labelize to hide symbols from screen
  # readers.
  #
  # @param [String, Symbol, nil]  text
  # @param [Boolean]              show_symbols  If *true*, don't #hide_symbols.
  # @param [Hash]                 opt           To super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see Emma::Common::FormatMethods#labelize
  #
  def labelize(text, show_symbols: false, **opt)
    value = super(text, **opt)
    show_symbols ? value : hide_symbols(value)
  end

end

__loading_end(__FILE__)
