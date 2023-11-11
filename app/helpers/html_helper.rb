# app/helpers/html_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper HTML support methods.
#
module HtmlHelper

  include CssHelper
  include EncodingHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Short-cut for generating an HTML '<div>' element.
  #
  # @param [*]        args            Passed to #html_tag.
  # @param [Hash]     opt             Passed to #html_tag.
  # @param [Proc]     blk             Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_div(*args, **opt, &blk)
    html_tag(:div, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<span>' element.
  #
  # @param [*]        args            Passed to #html_tag.
  # @param [Hash]     opt             Passed to #html_tag.
  # @param [Proc]     blk             Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_span(*args, **opt, &blk)
    html_tag(:span, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<button>' element.
  #
  # @param [*]        args            Passed to #html_tag.
  # @param [Hash]     opt             Passed to #html_tag.
  # @param [Proc]     blk             Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_button(*args, **opt, &blk)
    label   = args.first.presence
    symbols = only_symbols?(label)
    accessible_name?(*args, **opt) if Log.debug? && (symbols || label.blank?)
    args[0] = symbol_icon(label) if symbols
    html_tag(:button, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<details>' element.
  #
  # For easier styling, additional content is wrapped in a '.content' element.
  #
  # @param [String]   summary         The text visible when not expanded.
  # @param [Array<*>] content         Appended to the '.content' element.
  # @param [String]   id              Passed to the inner `<summary>` element.
  # @param [String]   title           Passed to the inner `<summary>` element.
  # @param [Hash]     opt             Passed to the outer `<details>` element.
  # @param [Proc]     blk             Appended to the '.content' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_details(summary, *content, id: nil, title: nil, **opt, &blk)
    title ||= 'Click to show details' # TODO: I18n
    summary = html_tag(:summary, summary, id: id, title: title)
    content = html_div(*content, class: 'content', &blk)
    html_tag(:details, **opt) do
      summary << content
    end
  end

  # Short-cut for generating an HTML element which normalizes element contents
  # provided via the parameter list and/or the block.
  #
  # If *tag* is a number it is translated to 'h1'-'h6'.  If *tag* is 0 or *nil*
  # then it defaults to 'div'.
  #
  # @param [Symbol, String, Integer, nil] tag
  # @param [*]                            args
  # @param [String, nil]                  separator   Between *args*.
  # @param [Hash]                         opt         Passed to #content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Additional content
  # @yieldreturn [String, Array]
  #
  # @see ActionView::Helpers::TagHelper#content_tag
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def html_tag(tag, *args, separator: "\n", **opt)
    level = positive(tag)
    tag   = nil if tag.is_a?(Numeric)
    tag   = level && ('h%d' % [level, 6].min) || tag || 'div'
    opt   = args.pop.dup if opt.blank? && args.last.is_a?(Hash)
    opt   = add_inferred_attributes(tag, opt)
    opt   = add_required_attributes(tag, opt)
    args.concat(Array.wrap(yield)) if block_given?
    args.flatten!
    args.compact_blank!
    check_required_attributes(tag, opt, meth: calling_method) if Log.debug?
    content_tag(tag, safe_join(args, separator), html_options!(opt))
  end

  # Invoke #form_tag after normalizing element contents provided via the
  # parameter list and/or the block.
  #
  # @param [String, Hash] url_or_path
  # @param [*]            args
  # @param [String, nil]  separator   Between *args*.
  # @param [Hash]         opt         Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_form(url_or_path, *args, separator: "\n", **opt)
    opt = args.pop if opt.blank? && args.last.is_a?(Hash)
    args.concat(Array.wrap(yield)) if block_given?
    args.flatten!
    args.compact_blank!
    form_tag(url_or_path, opt) do
      safe_join(args, separator)
    end
  end

  # An "empty" element that can be used as a placeholder.
  #
  # @param [String, nil] comment      Text for an interior HTML comment.
  # @param [Symbol]      tag          The HTML tag to use for the element.
  # @param [Hash]        opt          Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def placeholder_element(comment: nil, tag: :div, **opt)
    html_tag(tag, 'aria-hidden': true, **opt) do
      "<!-- #{comment} -->".html_safe if comment.present?
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # HTML attributes which indicate specification of an accessible name.
  #
  # @type [Array<Symbol>]
  #
  ARIA_LABEL_ATTRS = %i[
    aria-label
    aria-labelledby
    aria-describedby
  ].freeze

  # Indicate whether the HTML element to be created with the given arguments
  # appears to have an accessible name.
  #
  # @param [Array<*>] args
  # @param [Hash]     opt
  #
  def accessible_name?(*args, **opt)
    opt  = args.pop if args.last.is_a?(Hash) && opt.blank?
    name = args.first
    return true if name.present? && (name.html_safe? || !only_symbols?(name))
    return true if opt.slice(:title, *ARIA_LABEL_ATTRS).compact_blank!.present?
    Log.debug { "#{__method__}: none for #{args.inspect} #{opt.inspect}" }
    false
  end

  # A matcher for one or more symbol-like characters.
  #
  # @type [Regexp]
  #
  SYMBOLS = %w[
    \u2000-\u{FFFF}
    \u{1F000}-\u{1FFFF}
  ].join.then { |char_ranges| Regexp.new("[#{char_ranges}]+") }.freeze

  # Indicate whether the string contains only characters that fall outside the
  # normal text range.  Always `false` if *text* is not a string.
  #
  # @param [String, *] text
  #
  def only_symbols?(text)
    text.is_a?(String) && text.present? && text.remove(SYMBOLS).blank?
  end

  # Make a Unicode character (sequence) into a decorative element that is not
  # pronounced by screen readers.
  #
  # @param [String, Symbol, *] icon   Character(s) that should match #SYMBOLS.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt    Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def symbol_icon(icon, css: '.symbol', **opt)
    icon = icon.to_s unless icon.is_a?(String)
    opt[:'aria-hidden'] = true unless opt.key?(:'aria-hidden')
    prepend_css!(opt, css)
    html_span(icon, **opt)
  end

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
  }x

  # If the text has any symbols in it, hide them from screen readers.
  #
  # If so, each run of one or more symbolic characters will be wrapped in
  # span.symbol with 'aria-hidden' and all other runs of characters will be
  # wrapped in span.text (unless *text* is already ActiveSupport::SafeBuffer).
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

    # noinspection RubyMismatchedReturnType
    return html ? text : ERB::Util.h(text) unless text.match?(SYMBOLS)

    if html && (parts = text.scan(FOR_ELEMENTS)).present?
      # noinspection RubyMismatchedArgumentType
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

  # Augment Emma::Common::FormatMethods#non_breaking to hide symbols from
  # screen readers.
  #
  # @param [String, nil] text
  # @param [Boolean]     show_symbols   If *true* don't #hide_symbols.
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
  # @param [Boolean]              show_symbols  If *true* don't #hide_symbols.
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A line added to tooltips to indicate a .sign-in-required link.
  #
  # @type [String]
  #
  SIGN_IN = I18n.t('emma.download.failure.sign_in').freeze

  # Augment with options that should be set/unset according to the context
  # (e.g. CSS classes present).
  #
  # @param [Symbol, String]  tag
  # @param [Hash{Symbol=>*}] options
  #
  # @return [Hash]
  #
  def add_inferred_attributes(tag, options)
    opt = options.dup
    css = css_class_array(opt[:class])

    # Attribute defaults which may be overridden in *options*.
    css.each do |css_class|
      case css_class.to_sym
        when :hidden    then opt.reverse_merge!('aria-hidden':   true)
        when :disabled  then opt.reverse_merge!('aria-disabled': true)
        when :forbidden then opt.reverse_merge!('aria-disabled': true)
      end
    end

    # Attribute replacements which will override *options*.
    css.each do |css_class|
      case css_class
        when 'sign-in-required'
          if (tip = opt[:title].to_s).blank?
            opt[:title] = SIGN_IN
          elsif !tip.include?(SIGN_IN)
            opt[:title] = make_tooltip(tip, "(#{SIGN_IN})")
          end
      end
    end

    if %w[a button].include?(tag.to_s)
      opt.reverse_merge!(disabled: true) if opt[:'aria-disabled']
    end

    opt[:disabled] ? opt.reverse_merge!('aria-disabled': true) : opt
  end

  # Append additional line(s) options[:title].
  #
  # @param [Hash{Symbol=>*}] options
  # @param [Array<String>]   lines
  #
  # @return [Hash]                    The modified *options*.
  #
  def append_tooltip!(options, *lines)
    tooltip = make_tooltip(options[:title], *lines)
    options.merge!(title: tooltip)
  end

  # Create a multi-line tooltip.
  #
  # @param [String, nil]   title
  # @param [Array<String>] lines
  #
  # @return [String]
  #
  def make_tooltip(title, *lines)
    title = title.to_s.split("\n").compact_blank!.presence
    lines = lines.flat_map { |v| v.to_s.split("\n") }.compact_blank!.presence
    if title && lines
      norm = ->(v) { v.gsub(/[\s[:punct:]]+/, ' ').strip.downcase }
      last = norm.(title.last)
      lines.delete_if { |v| norm.(v) == last }
    end
    [*title, *lines].join("\n")
  end

  # Attributes that are expected for a given HTML tag and can be added
  # automatically.
  #
  # @param[Hash{Symbol=>Hash}]
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/CSS/display#tables
  #
  ADDED_HTML_ATTRIBUTES = {
    button: { type: 'button' },
    table:  { role: 'table' },
    thead:  { role: 'rowgroup' },
    tbody:  { role: 'rowgroup' },
    tfoot:  { role: 'rowgroup' },
    th:     { role: nil },            # Either 'columnheader' or 'rowheader'
    tr:     { role: 'row' },
    td:     { role: nil },            # Either 'cell' or 'gridcell'
  }.deep_freeze

  # Augment with default options.
  #
  # @param [Symbol, String]  tag
  # @param [Hash{Symbol=>*}] options
  #
  # @return [Hash]
  #
  def add_required_attributes(tag, options)
    attrs = ADDED_HTML_ATTRIBUTES[tag&.to_sym]
    attrs&.merge(options) || options
  end

  # Attributes that are expected for a given HTML tag.
  #
  # @param[Hash{Symbol=>Array<Symbol>}]
  #
  REQUIRED_HTML_ATTRIBUTES = {
    table: %i[role aria-rowcount aria-colcount],
    th:    %i[role],
    tr:    %i[role aria-rowindex],
    td:    %i[aria-colindex],
  }.freeze

  # Verify that options have been included unless 'aria-hidden'.
  #
  # @param [Symbol, String]  tag
  # @param [Hash{Symbol=>*}] options
  # @param [Symbol, nil]     meth     Calling method for diagnostics.
  #
  # @return [Boolean]                 If *false* at least one was missing.
  #
  def check_required_attributes(tag, options, meth: nil)
    return true if true?(options[:'aria-hidden'])
    required = Array.wrap(REQUIRED_HTML_ATTRIBUTES[tag&.to_sym])
    missing  = (required - options.keys).presence&.join(', ') or return true
    Log.debug { "#{meth || calling_method}: #{tag}: missing opt: #{missing}" }
    false
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # These are observed hash keys which may travel alongside HTML attributes
  # like :id, :class, :tabindex etc. when passed as named parameters, but
  # should not be passed into methods which actually generate HTML elements.
  #
  # @type [Array<Symbol>]
  #
  NON_HTML_ATTRIBUTES = %i[
    index
    level
    offset
    row
    skip
  ].freeze

  # Make a copy which has only valid HTML attributes with coalesced "data-*"
  # and `data: { }` options.
  #
  # @param [Hash, nil] html_opt       The target options hash.
  #
  # @return [Hash]
  #
  # @note Currently unused.
  #
  def html_options(html_opt)
    html_options!(dup_options(html_opt))
  end

  # Retain only entries which are valid HTML attributes with coalesced "data-*"
  # and `data: { }` options.
  #
  # @param [Hash] html_opt            The target options hash.
  #
  # @return [Hash]                    The modified *html_opt* hash.
  #
  def html_options!(html_opt)
    meth = html_opt.delete(:method).presence
    data = html_opt.delete(:data).presence
    html_opt.reverse_merge!(data.transform_keys { |k| :"data-#{k}" }) if data
    html_opt[:'data-method'] ||= meth if meth
    html_opt.except!(*NON_HTML_ATTRIBUTES)
  end

  # Merge values from one or more options hashes.
  #
  # @param [Hash, nil]       html_opt   The target options hash.
  # @param [Array<Hash,nil>] args       Options hash(es) to merge into *opt*.
  #
  # @return [Hash]                      A new hash.
  #
  # @see #merge_html_options!
  #
  def merge_html_options(html_opt, *args)
    html_opt = html_opt&.dup || {}
    # noinspection RubyMismatchedArgumentType
    merge_html_options!(html_opt, *args)
  end

  # Merge values from one or more hashes into an options hash.
  #
  # @param [Hash]            html_opt   The target options hash.
  # @param [Array<Hash,nil>] args       Options hash(es) to merge into *opt*.
  #
  # @return [Hash]                      The modified *opt* hash.
  #
  # @see #append_css!
  #
  def merge_html_options!(html_opt, *args)
    args    = args.map { |a| a[:class] ? a.dup : a if a.is_a?(Hash) }.compact
    classes = args.map { |a| a.delete(:class) }.compact
    append_css!(html_opt, *classes).merge!(*args)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.include(ActionView::Helpers::TagHelper)
    base.extend(ActionView::Helpers::TagHelper)
    base.extend(ActionView::Helpers::UrlHelper)
    base.extend(self)
  end

end

__loading_end(__FILE__)
