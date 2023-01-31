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
  # @param [Array<*>] args            Passed to #html_tag.
  # @param [Proc]     block           Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_div(*args, &block)
    html_tag(:div, *args, &block)
  end

  # Short-cut for generating an HTML '<span>' element.
  #
  # @param [Array<*>] args            Passed to #html_tag.
  # @param [Proc]     block           Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_span(*args, &block)
    html_tag(:span, *args, &block)
  end

  # Short-cut for generating an HTML '<button>' element.
  #
  # @param [Array<*>] args            Passed to #html_tag.
  # @param [Proc]     block           Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_button(*args, &block)
    html_tag(:button, *args, &block)
  end

  # Short-cut for generating an HTML '<details>' element.
  #
  # For easier styling, additional content is wrapped in a '.content' element.
  #
  # @param [String]   summary         The text visible when not expanded.
  # @param [Array<*>] content         Appended to the '.content' element.
  # @param [Hash]     opt             Passed to the outer '<details>' element.
  # @param [Proc]     block           Appended to the '.content' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_details(summary, *content, **opt, &block)
    tooltip = opt.delete(:title) || 'Click to show details' # TODO: I18n
    summary = html_tag(:summary, summary, title: tooltip)
    content = html_div(*content, class: 'content', &block)
    html_tag(:details, opt) do
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
  # @param [Array]                        args
  #
  # @option args.last [String] :separator
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Additional content
  # @yieldreturn [String, Array]
  #
  # @see ActionView::Helpers::TagHelper#content_tag
  #
  #--
  # == Variations
  #++
  #
  # @overload html_tag(tag, content, *more_content, options = nil)
  #   @param [Symbol, String, Integer, nil]                tag
  #   @param [ActiveSupport::SafeBuffer, String, nil]      content
  #   @param [Array<ActiveSupport::SafeBuffer,String,nil>] more_content
  #   @param [Hash, nil]                                   options
  #
  # @overload html_tag(tag, options = nil, &block)
  #   @param [Symbol, String, Integer, nil]                tag
  #   @param [Hash, nil]                                   options
  #   @param [Proc]                                        block
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def html_tag(tag, *args)
    level = positive(tag)
    level &&= [level, 6].min
    tag = "h#{level}" if level
    tag = 'div'       if tag.blank? || tag.is_a?(Integer)
    options   = add_needed_attributes(tag, args.extract_options!)
    separator = options.delete(:separator) || "\n"
    content   = [*args, *(yield if block_given?)].flatten.compact_blank!
    check_required_attributes(tag, options) if Log.debug?
    content_tag(tag, safe_join(content, separator), html_options!(options))
  end

  # Invoke #form_tag after normalizing element contents provided via the
  # parameter list and/or the block.
  #
  # @param [String, Hash] url_or_path
  # @param [Array<*>]     args        Passed to #form_tag except for:
  #
  # @option args.last [String] :separator   Default: "\n"
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_form(url_or_path, *args)
    options   = args.last.is_a?(Hash) ? args.pop.dup : {}
    separator = options.delete(:separator) || "\n"
    content   = args.flatten
    content  += Array.wrap(yield) if block_given?
    content   = content.compact_blank
    form_tag(url_or_path, options) do
      safe_join(content, separator)
    end
  end

  # An "empty" element that can be used as a placeholder.
  #
  # @param [Hash] opt                         Passed to #html_div except for:
  #
  # @option opt [String]            :comment  The text of an HTML comment to
  #                                             place inside the empty element.
  # @option opt [Symbol,String,Integer] :tag  The HTML tag to use for the
  #                                             element instead of *div*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def placeholder_element(**opt)
    tag     = opt.delete(:tag) || :div
    comment = opt.delete(:comment)
    opt[:'aria-hidden'] = true
    html_tag(tag, opt) do
      "<!-- #{comment} -->".html_safe if comment.present?
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
    th:     { role: nil }, # Either 'columnheader' or 'rowheader'
    tr:     { role: 'row' },
    td:     { role: 'cell' },
  }.deep_freeze

  # Augment with default options.
  #
  # @param [Symbol, String]  tag
  # @param [Hash{Symbol=>*}] options
  #
  # @return [Hash]
  #
  def add_needed_attributes(tag, options)
    required = ADDED_HTML_ATTRIBUTES[tag&.to_sym] || {}
    required.merge(options)
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

  # Verify that options have been included.
  #
  # @param [Symbol, String]  tag
  # @param [Hash{Symbol=>*}] options
  #
  # @return [Boolean]                 If *false* at least one was missing.
  #
  def check_required_attributes(tag, options)
    required = Array.wrap(REQUIRED_HTML_ATTRIBUTES[tag&.to_sym])
    missing  = (required - options.keys).presence
    Log.debug { "#{tag}: missing opt: #{missing.join(',')}" } if missing
    missing.nil?
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
