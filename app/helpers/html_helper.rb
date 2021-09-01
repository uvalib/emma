# app/helpers/html_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper HTML support methods.
#
module HtmlHelper

  include CssHelper

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

  # Short-cut for generating an HTML "<button>" element.
  #
  # @param [Array] args               Passed to #html_tag.
  # @param [Proc]  block              Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_button(*args, &block)
    html_tag(:button, *args, &block)
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
  def html_tag(tag, *args)
    level = positive(tag)
    level &&= [level, 6].min
    tag = "h#{level}" if level
    tag = 'div'       if tag.blank? || tag.is_a?(Integer)
    options   = args.last.is_a?(Hash) ? args.pop.dup : {}
    separator = options.delete(:separator) || "\n"
    content   = args.flatten
    content  += Array.wrap(yield) if block_given?
    content   = content.compact_blank
    content_tag(tag, safe_join(content, separator), html_options!(options))
  end

  # Invoke #form_tag after normalizing element contents provided via the
  # parameter list and/or the block.
  #
  # @param [String] url_or_path
  # @param [Array]  args              Passed to #form_tag except for:
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
    html_tag(tag, opt) do
      "<!-- #{comment} -->".html_safe if comment.present?
    end
  end

  # Generate a symbol-based icon button or link which should be both accessible
  # and cater to the quirks of various accessibility scanners.
  #
  # @param [String, nil] icon         Default: Emma::Unicode#STAR
  # @param [String, nil] text         Default: 'Action'
  # @param [String, nil] url          Default: '#'
  # @param [Hash]        opt          Passed to #link_to or #html_span except:
  #
  # @option opt [String] :symbol      Overrides *symbol*
  # @option opt [String] :text        Overrides *text*
  # @option opt [String] :url         Overrides *url*
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RubyMismatchedParameterType
  #++
  def icon_button(icon: nil, text: nil, url: nil, **opt)
    icon           ||= STAR
    text           ||= opt[:title] || 'Action' # TODO: I18n
    opt[:title]    ||= text
    opt[:role]     ||= 'button'
    opt[:tabindex] ||= 0 unless url

    sr_only = html_span(text, class: 'text sr-only')
    symbol  = html_span(icon, class: 'symbol', 'aria-hidden': true)
    link    = sr_only << symbol

    if url
      make_link(link, url, **opt)
    else
      html_span(link, opt)
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
    sign_in  = has_class?(opt, 'sign-in-required')
    disabled = has_class?(opt, 'disabled', 'forbidden')
    if sign_in
      opt[:tabindex]   = 0 unless opt.key?(:tabindex)
      opt[:onkeypress] = 'return false;'
      disabled = true
    end
    if disabled
      opt[:'aria-disabled'] = true
    elsif opt[:target] == '_blank'
      note = 'opens in a new window' # TODO: I18n
      if opt[:title].blank?
        opt[:title] = "(#{note.capitalize}.)"
      elsif !opt[:title].to_s.downcase.include?(note)
        opt[:title] = "#{opt[:title]}\n(#{note})"
      end
    end
    unless opt.key?(:rel)
      opt[:rel] = 'noopener' if path.start_with?('http')
    end
    unless opt.key?(:tabindex)
      opt[:tabindex] = -1 if opt[:'aria-hidden']
    end
    unless opt.key?(:'aria-hidden')
      opt[:'aria-hidden'] = true if opt[:tabindex] == -1
    end
    label = opt.delete(:label) || label
    link_to(label, path, html_options!(opt), &block)
  end

  # Produce a link to an external site which opens in a new browser tab.
  #
  # @param [String] label
  # @param [String] path
  # @param [Hash]   opt
  # @param [Proc]   block
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #make_link
  #
  def external_link(label, path, **opt, &block)
    opt[:target] = '_blank' unless opt.key?(:target)
    make_link(label, path, **opt, &block)
  end

  # Produce a link to download an item to the client's browser.
  #
  # @param [String] label
  # @param [String] path
  # @param [Hash]   opt
  # @param [Proc]   block
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #external_link
  #
  def download_link(label, path, **opt, &block)
    css_selector = '.download'
    external_link(label, path, **prepend_classes!(opt, css_selector), &block)
  end

  # If *text* is a URL return it directly; if *text* is HTML, locate the first
  # "href" and return the indicated value.
  #
  # @param [String, nil] text
  #
  # @return [String]                  A full URL.
  # @return [nil]                     No URL could be extracted.
  #
  def extract_url(text)
    url = text.to_s.strip
    unless url.blank? || url.start_with?('http')
      url = url.tr("\n", ' ').sub!(/.*href=["']([^"']{2,})["'].*/, '\1')
      unless url.blank? || url.start_with?('http')
        url = url.remove!(/^[^?]+\?url=/) && CGI.unescape(url)
      end
    end
    url.presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  # @see #append_classes!
  #
  def merge_html_options!(html_opt, *args)
    args    = args.map { |a| a[:class] ? a.dup : a if a.is_a?(Hash) }.compact
    classes = args.map { |a| a.delete(:class) }.compact
    append_classes!(html_opt, *classes).merge!(*args)
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

  # Render a table of values.
  #
  # @param [Hash] pairs               Key-value pairs to display.
  # @param [Hash] opt                 Passed to outer #html_div except for:
  #                                     #GRID_OPTS and
  #
  # @option opt [Boolean] :wrap       If *true* then key/value pairs are joined
  #                                     within a wrapper element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_table(pairs, **opt)
    opt, html_opt = partition_hash(opt, :wrap, *GRID_OPTS)
    wrap = opt.delete(:wrap)
    opt[:row]     ||= 0
    opt[:col]     ||= 0
    opt[:row_max] ||= pairs.size
    opt[:col_max] ||= 1
    html_div(html_opt) do
      pairs.map do |key, value|
        opt[:col] = 0  if opt[:col] == opt[:col_max]
        opt[:row] += 1 if opt[:col].zero?
        opt[:col] += 1
        r_opt = { class: grid_cell_classes(**opt) }
        k_opt = prepend_classes(r_opt, 'key')
        v_opt = prepend_classes(r_opt, 'value')
        if wrap
          prepend_classes!(r_opt, 'entry')
          html_div(r_opt) do
            key = html_div(k_opt) { ERB::Util.h(key) << ':' }
            key << '&nbsp;'.html_safe << html_div(value, v_opt)
          end
        else
          html_div(key, k_opt) << html_div(value, v_opt)
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Safely truncate either normal or html_safe strings via #html_truncate.
  #
  # @param [ActiveSupport::SafeBuffer, String] str
  # @param [Integer, nil]                      length
  # @param [Hash]                              opt
  #
  # @return [ActiveSupport::SafeBuffer]   If *str* was html_safe.
  # @return [String]                      If *str* was not HTML.
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
  # @param [Integer, nil] length          Def: `#HTML_TRUNCATE_MAX_LENGTH`
  # @param [Hash]         opt
  #
  # @option opt [Boolean]     :content    If *true*, base on content size.
  # @option opt [String, nil] :omission   Def: `#HTML_TRUNCATE_OMISSION`
  # @option opt [String, nil] :separator  Def: `#HTML_TRUNCATE_SEPARATOR`
  #
  # @return [ActiveSupport::SafeBuffer]   If *str* was html_safe.
  # @return [String]                      If *str* was not HTML.
  #
  # == Usage Notes
  # Since *str* may be a sequence of HTML elements or even just a text string
  # with HTML entities, it is wrapped in a "<div>" to make sure that the
  # Nokogiri parser is dealing with valid XML.
  #
  # @note The result has UTF-8 encoding (even if no truncation was performed).
  #
  def self.html_truncate(str, length = nil, **opt)
    length ||= HTML_TRUNCATE_MAX_LENGTH
    str = to_utf8(str)
    return str if str.size <= length
    opt[:omission]  &&= to_utf8(opt[:omission])
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
  # @param [Integer, nil]        len      Def: `#HTML_TRUNCATE_MAX_LENGTH`
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
    doc        = xml.document

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
                # noinspection Rails3Deprecated
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
        Nokogiri::XML::Text.new(text, doc)
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
          node << Nokogiri::XML::Text.new(omission, doc)
        end
      end
      if node.children.present?
        node
      elsif max_length >= omission.size
        Nokogiri::XML::Text.new(omission, doc)
      end

    else
      node         = blank_copy(xml)
      remaining    = max_length
      has_omission = false
      xml.children.each do |child|
        # noinspection RubyNilAnalysis
        if remaining < omission.size
          break
        elsif remaining == omission.size
          node << Nokogiri::XML::Text.new(omission, doc) unless has_omission
          break
        elsif (child = xml_truncate(child, remaining, **opt)).nil?
          return
        else
          # noinspection RubyNilAnalysis
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

  # Convert a string to UTF-8 encoding.
  #
  # @param [ActiveSupport::SafeBuffer, String, nil] str
  #
  # @return [ActiveSupport::SafeBuffer]   If *str* was HTML-safe.
  # @return [String]                      Otherwise.
  #
  def self.to_utf8(str)
    res  = str&.to_s || ''
    enc  = res.encoding
    return res if enc == Encoding::UTF_8
    html = res.html_safe?
    res  = Encoding::Converter.new(enc, 'utf-8').convert(res)
    html ? res.html_safe : res
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:include, ActionView::Helpers::TagHelper)
    base.send(:extend,  ActionView::Helpers::TagHelper)
    base.send(:extend,  ActionView::Helpers::UrlHelper)
    base.send(:extend,  self)
  end

end

__loading_end(__FILE__)
