# app/helpers/html_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared HTML support methods.
#
module HtmlHelper

  def self.included(base)

    __included(base, '[HtmlHelper]')

    base.send(:include, ActionView::Helpers::TagHelper)
    base.send(:extend,  ActionView::Helpers::TagHelper)
    base.send(:extend,  ActionView::Helpers::UrlHelper)
    base.send(:extend,  self)

  end

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Short-cut for generating an HTML "<div>" element.
  #
  # @param [Array] args               Passed to #html_tag.
  # @param [Proc]  block              Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_div(*args, &block)
    html_tag(:div, *args, &block)
  end

  # Short-cut for generating an HTML "<span>" element.
  #
  # @param [Array] args               Passed to #html_tag.
  # @param [Proc]  block              Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_span(*args, &block)
    html_tag(:span, *args, &block)
  end

  # Short-cut for generating an HTML element.
  #
  # If *tag* is a number it is translated to 'h1'-'h6'.  If *tag* is 0 or *nil*
  # then it defaults to 'div'.
  #
  # @param [Symbol, String, Integer, nil] tag
  # @param [Array]                        args
  #
  # @yield Additional content
  # @yieldreturn [String, Array]
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Variations
  #
  # @overload html_tag(tag, content, options = nil, escape = true)
  #   @param [Symbol, String, Integer, nil]           tag
  #   @param [ActiveSupport::SafeBuffer, String, nil] content
  #   @param [Hash]                                   options
  #   @param [Boolean]                                escape
  #
  # @overload html_tag(tag, options = nil, escape = true, &block)
  #   @param [Symbol, String, Integer, nil]           tag
  #   @param [Hash]                                   options
  #   @param [Boolean]                                escape
  #   @param [Proc]                                   block
  #
  # @see ActionView::Helpers::TagHelper#content_tag
  #
  def html_tag(tag, *args)
    level = positive(tag)
    level &&= [level, 6].min
    tag = "h#{level}" if level
    tag = 'div'       if tag.blank? || tag.is_a?(Integer)
    options = args.extract_options!
    content = args.flatten
    content += Array.wrap(yield) if block_given?
    content.reject!(&:blank?)
    content_tag(tag, safe_join(content, "\n"), options)
  end

  # An "empty" element that can be used as a placeholder.
  #
  # @param [Hash] opt                 Passed to #html_div except for:
  #
  # @option opt [String]                :comment  The text of an HTML comment
  #                                                 to place inside the empty
  #                                                 element.
  # @option opt [Symbol,String,Integer] :tag      The HTML tag to use for the
  #                                                 element instead of "<div>".
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def placeholder_element(**opt)
    tag     = opt.delete(:tag) || :div
    comment = opt.delete(:comment)
    opt[:'aria-hidden'] = true
    html_tag(tag, **opt) do
      "<!-- #{comment} -->".html_safe if comment.present?
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a link with appropriate accessibility settings.
  #
  # @param [String] label
  # @param [String] path
  # @param [Hash]   opt               Passed to #link_to except for:
  # @param [Proc]   block             Passed to #link_to.
  #
  # @option opt [String] :label       Overrides *label* parameter if present.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # This method assumes that local paths are always relative.
  #
  def make_link(label, path, **opt, &block)
    disabled = has_class?(opt, 'disabled')
    if (opt[:target] == '_blank') && !disabled
      opt[:title] &&= "#{opt[:title]}\n(opens in a new window)" # TODO: I18n
      opt[:title] ||= '(Opens in a new window.)'                # TODO: I18n
    end
    unless opt.key?(:rel)
      opt[:rel] = 'noopener' if path.start_with?('http')
    end
    unless opt.key?(:tabindex)
      opt[:tabindex] = -1 if opt[:'aria-hidden'] || disabled
    end
    unless opt.key?(:'aria-hidden')
      opt[:'aria-hidden'] = true if opt[:tabindex] == -1
    end
    label = opt.delete(:label) || label
    link_to(label, path, opt, &block)
  end

  # Produce a link to an external site which opens in a new browser tab.
  #
  # @param [String] label             Passed to #make_link.
  # @param [String] path              Passed to #make_link.
  # @param [Hash]   opt               Passed to #make_link.
  # @param [Proc]   block             Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def external_link(label, path, **opt, &block)
    opt[:target] = '_blank' unless opt.key?(:target)
    make_link(label, path, **opt, &block)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the HTML options include any of the given CSS classes.
  #
  # @param [Hash, nil]     opt        The target options hash.
  # @param [Array<String>] classes    CSS classes to find.
  #
  def has_class?(opt, *classes)
    opt_classes = opt&.dig(:class)
    opt_classes = opt_classes.to_s.split(' ') if opt_classes.is_a?(String)
    Array.wrap(opt_classes).any? { |c| classes.include?(c) }
  end

  # Merge values from one or more options hashes.
  #
  # @param [Hash, nil]   opt          The target options hash.
  # @param [Array<Hash>] args         Options hash(es) to merge into *opt*.
  #
  # @return [Hash]                    A new hash.
  #
  # @see #merge_html_options!
  #
  def merge_html_options(opt, *args)
    merge_html_options!(opt&.dup, *args)
  end

  # Merge values from one or more hashes into an options hash.
  #
  # @param [Hash, nil]   opt          The target options hash.
  # @param [Array<Hash>] args         Options hash(es) to merge into *opt*.
  #
  # @return [Hash]                    The modified *opt* hash.
  #
  # @see #append_css_classes!
  #
  def merge_html_options!(opt, *args)
    opt ||= {}
    args.each do |arg|
      next unless arg.is_a?(Hash)
      opt.merge!(arg.except(:class))
      append_css_classes!(opt, arg[:class])
    end
    opt
  end

  # If CSS class name(s) are provided, return a copy of *opt* where the names
  # are appended to the existing `opt[:class]` value.
  #
  # @param [Hash, nil]           opt    The source options hash (if present).
  # @param [Array<String,Array>] args   CSS class names.
  # @param [Proc]                block  Passed to #append_css_classes!.
  #
  # @return [Hash]                      A new hash with :class set.
  #
  def append_css_classes(opt, *args, &block)
    if opt && !opt.is_a?(Hash)
      args.unshift(opt)
      opt = nil
    end
    append_css_classes!(opt&.dup, *args, &block)
  end

  # If CSS class name(s) are provided, append them to the existing
  # `opt[:class]` value.
  #
  # @param [Hash, nil]           opt    The target options hash.
  # @param [Array<String,Array>] args   CSS class names.
  # @param [Proc]                block  Passed to #css_classes.
  #
  # @return [Hash]                      The modified *opt* hash.
  #
  # Compare with:
  # @see #prepend_css_classes!
  #
  def append_css_classes!(opt, *args, &block)
    opt  ||= {}
    added  = css_classes(*args, &block)
    result = (current = opt[:class]) ? css_classes(current, added) : added
    opt.merge!(class: result)
  end

  # If CSS class name(s) are provided, return a copy of *opt* where the names
  # are prepended to the existing `opt[:class]` value.
  #
  # @param [Hash, nil]           opt    The source options hash (if present).
  # @param [Array<String,Array>] args   CSS class names.
  # @param [Proc]                block  Passed to #prepend_css_classes!.
  #
  # @return [Hash]                      A new hash with :class set.
  #
  def prepend_css_classes(opt, *args, &block)
    if opt && !opt.is_a?(Hash)
      args.unshift(opt)
      opt = nil
    end
    prepend_css_classes!(opt&.dup, *args, &block)
  end

  # If CSS class name(s) are provided, prepend them to the existing
  # `opt[:class]` value.
  #
  # @param [Hash, nil]           opt    The target options hash.
  # @param [Array<String,Array>] args   CSS class names.
  # @param [Proc]                block  Passed to #css_classes.
  #
  # @return [Hash]                      The modified *opt* hash.
  #
  # Compare with:
  # @see #append_css_classes!
  #
  def prepend_css_classes!(opt, *args, &block)
    opt  ||= {}
    added  = css_classes(*args, &block)
    result = (current = opt[:class]) ? css_classes(added, current) : added
    opt.merge!(class: result)
  end

  # Combine arrays and space-delimited strings to produce a space-delimited
  # string of CSS class names for use inline.
  #
  # @param [Array<String,Array>] args
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [classes] Exposes *args* so the block may modify it.
  # @yieldparam  [Array<String>] classes  The initial set of CSS classes.
  # @yieldreturn [void]                   Return ignored.
  #
  def css_classes(*args)
    yield(args) if block_given?
    args.flat_map { |a|
      a.is_a?(Array) ? a : a.to_s.squish.split(' ') if a.present?
    }.compact.uniq.join(' ').html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Options consumed by internal methods which should not be passed on along to
  # the methods which generate HTML elements.
  #
  # @type [Array<Symbol>]
  #
  # @see #grid_cell_classes
  #
  GRID_OPTS = %i[row col row_max col_max].freeze

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash, nil]     html_opt
  # @param [Array<String>] classes
  # @param [Hash]          opt        Passed to #append_grid_cell_classes!.
  #
  # @return [Hash]                    A new hash.
  #
  def append_grid_cell_classes(html_opt, *classes, **opt)
    append_grid_cell_classes!(html_opt&.dup, *classes, **opt)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash, nil]     html_opt
  # @param [Array<String>] classes
  # @param [Hash]          opt        Passed to #grid_cell_classes.
  #
  # @return [Hash]                    The modified *html_opt* hash.
  #
  def append_grid_cell_classes!(html_opt, *classes, **opt)
    classes = grid_cell_classes(*classes, **opt)
    append_css_classes!(html_opt, *classes)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash, nil]     html_opt
  # @param [Array<String>] classes
  # @param [Hash]          opt        Passed to #prepend_grid_cell_classes!.
  #
  # @return [Hash]                    A new hash.
  #
  def prepend_grid_cell_classes(html_opt, *classes, **opt)
    prepend_grid_cell_classes!(html_opt&.dup, *classes, **opt)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash, nil]     html_opt
  # @param [Array<String>] classes
  # @param [Hash]          opt        Passed to #grid_cell_classes.
  #
  # @return [Hash]                    The modified *html_opt* hash.
  #
  def prepend_grid_cell_classes!(html_opt, *classes, **opt)
    classes = grid_cell_classes(*classes, **opt)
    prepend_css_classes!(html_opt, *classes)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Array<String>] classes
  # @param [Hash]          opt
  #
  # @option opt [String]  :class
  # @option opt [Integer] :row        Grid row (wide screen).
  # @option opt [Integer] :col        Grid column (wide screen).
  # @option opt [Integer] :row_max    Bottom grid row (wide screen).
  # @option opt [Integer] :col_max    Rightmost grid column (wide screen).
  # @option opt [Boolean] :sr_only    If *true*, include 'sr-only' CSS class.
  #
  # @return [Array<String>]
  #
  def grid_cell_classes(*classes, **opt)
    row = positive(opt[:row])
    col = positive(opt[:col])
    classes += Array.wrap(opt[:class])
    classes << "row-#{row}" if row
    classes << "col-#{col}" if col
    classes << 'row-first'  if row == 1
    classes << 'col-first'  if col == 1
    classes << 'row-last'   if row == opt[:row_max].to_i
    classes << 'col-last'   if col == opt[:col_max].to_i
    classes << 'sr-only'    if opt[:sr_only]
    classes.compact.uniq
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default number of digits produced by #hex_rand.
  #
  # @type [Integer]
  #
  HEX_RAND_DEFAULT_DIGITS = 8

  # Generate a string of random hex digits.
  #
  # @param [Integer] digits
  # @param [Boolean] upper            If *false* show lowercase hex digits.
  #
  # @return [String]
  #
  def hex_rand(digits = nil, upper: nil)
    digits = digits.to_i
    digits = HEX_RAND_DEFAULT_DIGITS unless digits.positive?
    format = "%0#{digits}X"
    format = format.downcase if upper.is_a?(FalseClass)
    limit  = 16.pow(digits) - 1
    format % rand(0..limit)
  end

  # Create a unique CSS identifier from *base* and a random hex digit string.
  #
  # @param [String] base
  #
  # @return [String]
  #
  def css_randomize(base)
    [base, hex_rand].join('-')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Safely truncate either normal or html_safe strings via #html_truncate.
  #
  # @param [ActiveSupport::SafeBuffer, String] str
  # @param [Integer]                           length
  # @param [Hash]                              opt
  #
  # @return [ActiveSupport::SafeBuffer, String]
  #
  # @see #html_truncate
  #
  def safe_truncate(str, length = nil, **opt)
    HtmlHelper.html_truncate(str, length, **opt)
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  HTML_TRUNCATE_MAX_LENGTH = 1024
  HTML_TRUNCATE_OMISSION   = '…'
  HTML_TRUNCATE_SEPARATOR  = nil

  # Truncate either normal or html_safe strings.
  #
  # If *str* is html_safe, it is assumed that it is HTML content and it is
  # processed by #xml_truncate.  Otherwise, String#truncate is used.
  #
  # @param [ActiveSupport::SafeBuffer, String] str
  # @param [Integer] length               Def: `#HTML_TRUNCATE_MAX_LENGTH`
  # @param [Hash]    opt
  #
  # @option opt [Boolean]     :content    If *true*, base on content size.
  # @option opt [String, nil] :omission   Def: `#HTML_TRUNCATE_OMISSION`
  # @option opt [String, nil] :separator  Def: `#HTML_TRUNCATE_SEPARATOR`
  #
  # @return [ActiveSupport::SafeBuffer, String]
  #
  # == Usage Notes
  # Since *str* may be a sequence of HTML elements or even just a text string
  # with HTML entities, it is wrapped in a "<div>" to make sure that the
  # Nokogiri parser is dealing with valid XML.
  #
  def self.html_truncate(str, length = nil, **opt)
    length ||= HTML_TRUNCATE_MAX_LENGTH
    str = str&.to_s || ''
    return str if str.size <= length
    opt[:omission]  ||= HTML_TRUNCATE_OMISSION
    opt[:separator] ||= HTML_TRUNCATE_SEPARATOR
    if str.html_safe?
      xs  = '<div>'
      xe  = xs.sub('<', '</')
      xml = "#{xs}#{str.strip}#{xe}"
      xml = Nokogiri::HTML::DocumentFragment.parse(xml)
      xml = xml_truncate(xml, length, **opt)
      xml = xml&.to_html(save_with: (2 | 4 | 64)) || ''
      xml.delete_prefix!(xs)
      xml.delete_suffix!(xe)
      xml.squeeze!(opt[:omission])
      xml.html_safe
    else
      str.truncate(length, opt.except(:content))
    end
  end

  # Truncate XML so that the rendered result is limited to the given length.
  #
  # If truncation is required it is done by truncating the content of
  # Nokogiri::XML::Text nodes.  If there is not enough room for even a single
  # character inside the final element then that element will not be included.
  #
  # @param [Nokogiri::XML::Node] xml
  # @param [Integer]             len      Def: `#HTML_TRUNCATE_MAX_LENGTH`
  # @param [Hash]                opt
  #
  # @option opt [Boolean]     :content    If *true*, base on content size.
  # @option opt [String, nil] :omission   Def: `#HTML_TRUNCATE_OMISSION`
  # @option opt [String, nil] :separator  Def: `#HTML_TRUNCATE_SEPARATOR`
  #
  # @return [Nokogiri::XML::Node]
  # @return [nil]
  #
  # == Usage Notes
  # May be problematic for small *len* values, depending on the nature of the
  # *xml* input, but generally the result will fit within *len* (even if it
  # is overly-aggressive in pruning the element hierarchy at the point where
  # the available length budget runs out).
  #
  def self.xml_truncate(xml, len = nil, **opt)
    opt[:omission] = HTML_TRUNCATE_OMISSION unless opt.key?(:omission)
    omission   = opt[:omission] ||= ''
    separator  = opt[:separator].presence
    max_length = len || HTML_TRUNCATE_MAX_LENGTH
    length     = (opt[:content] ? xml.content : xml.to_s).size

    if max_length >= length
      xml.dup

    elsif xml.is_a?(Nokogiri::XML::Text)
      last = max_length - omission.size
      unless last.negative?
        text = xml.content
        text =
          if opt[:content] || ((html = xml.to_s) == text)
            # No HTML entities, just simple characters.
            last = text.rindex(separator, last) || last if separator
            text.slice(0, last)
          else
            # Do not break within an HTML entity.  HTML entities have to be
            # converted to their Unicode equivalent in order to pass them into
            # the Nokogiri::XML::Text constructor.
            lookup = Nokogiri::HTML::NamedCharacters
            part   = []
            html.split(/&([^;]+);/) do |str|
              code = $1.to_s
              next if str == code # NOTE: Why?
              if str.size > last
                part << str.first(last)
                break
              elsif str.size.positive?
                part << str
                last -= str.size
              end
              entity = "&#{code};"
              next if code.blank? || (entity.size > last)
              last  -= entity.size
              code   = lookup[code] unless code.delete_prefix!('#')
              part << code.to_i.chr
            end
            part_index = separator  && part.rindex(separator)
            char_index = part_index && part[part_index].rindex(separator)
            part[part_index].slice!(0, char_index) if char_index
            part.join
          end
        text << omission
        Nokogiri::XML::Text.new(text, xml.parent)
      end

    elsif xml.children[0].is_a?(Nokogiri::XML::Text) && xml.children[1].nil?
      node       = blank_copy(xml)
      node_chars = node.to_s.size
      remaining  = max_length - node_chars
      if remaining.positive?
        text = xml_truncate(xml.children.first, remaining, **opt)
        size = text ? (opt[:content] ? text.content : text.to_s).size : 0
        if size >= omission.size
          node << text
        elsif max_length >= (node_chars + omission.size)
          node << Nokogiri::XML::Text.new(omission, node)
        end
      end
      if node.children.present?
        node
      elsif max_length >= omission.size
        Nokogiri::XML::Text.new(omission, xml.parent)
      end

    else
      node         = blank_copy(xml)
      remaining    = max_length
      has_omission = false
      xml.children.each do |child|
        if remaining < omission.size
          break
        elsif remaining == omission.size
          node << Nokogiri::XML::Text.new(omission, node) unless has_omission
          break
        elsif (child = xml_truncate(child, remaining, **opt)).nil?
          return
        else
          length = (opt[:content] ? child.content : child.to_s).size
          break if (length > remaining) && node.children.present?
          remaining   -= length
          has_omission = child.content.end_with?(omission)
          node << child
        end
      end
      node if node.children.present?
    end
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  private

  # Copy of an XML node without its children.
  #
  # @param [Nokogiri::XML::Node] node
  #
  # @return [Nokogiri::XML::Node]
  #
  def self.blank_copy(node)
    result = node.dup
    result.children.remove
    result
  end

end

__loading_end(__FILE__)
