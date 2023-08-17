# app/helpers/xml_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# XML-related methods.
#
module XmlHelper

  include EncodingHelper

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  HTML_TRUNCATE_MAX_LENGTH = 1024
  HTML_TRUNCATE_OMISSION   = '…'
  HTML_TRUNCATE_SEPARATOR  = nil

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Truncate either normal or html_safe strings.
  #
  # If *str* is html_safe, it is assumed that it is HTML content and it is
  # processed by #xml_truncate.  Otherwise, String#truncate is used.
  #
  # @param [ActiveSupport::SafeBuffer, String] str
  # @param [Integer, nil] length            Def: `#HTML_TRUNCATE_MAX_LENGTH`
  # @param [Hash]         opt
  #
  # @option opt [Boolean]      :content     If *true*, base on content size.
  # @option opt [String, nil]  :omission    Def: `#HTML_TRUNCATE_OMISSION`
  # @option opt [String, nil]  :separator   Def: `#HTML_TRUNCATE_SEPARATOR`
  # @option opt [Boolean, nil] :xhr         Encode for message headers.
  #
  # @return [ActiveSupport::SafeBuffer]     If *str* was html_safe.
  # @return [String]                        If *str* was not HTML.
  #
  # === Usage Notes
  # Since *str* may be a sequence of HTML elements or even just a text string
  # with HTML entities, it is wrapped in a '<div>' to make sure that the
  # Nokogiri parser is dealing with valid XML.
  #
  # @note The result has UTF-8 encoding (even if no truncation was performed).
  #
  def html_truncate(str, length = nil, **opt)
    length ||= HTML_TRUNCATE_MAX_LENGTH
    str = to_utf(str, **opt)
    # noinspection RubyMismatchedArgumentType
    return str if str.bytesize <= length
    opt[:omission] ||= HTML_TRUNCATE_OMISSION
    opt[:omission] = to_utf(opt[:omission], **opt)
    if str.html_safe?
      opt[:separator] ||= HTML_TRUNCATE_SEPARATOR
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
      # Correct String#truncate handling of Unicode :omission size.
      length -= opt[:omission].bytesize - opt[:omission].length
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
  # === Usage Notes
  # May be problematic for small *len* values, depending on the nature of the
  # *xml* input, but generally the result will fit within *len* (even if it
  # is overly-aggressive in pruning the element hierarchy at the point where
  # the available length budget runs out).
  #
  def xml_truncate(xml, len = nil, **opt)
    opt[:omission] = HTML_TRUNCATE_OMISSION unless opt.key?(:omission)
    omission   = opt[:omission] ||= ''
    omit_len   = omission.bytesize
    separator  = opt[:separator].presence
    max_length = len || HTML_TRUNCATE_MAX_LENGTH
    child_len  = (opt[:content] ? xml.content : xml.to_s).bytesize
    doc        = xml.document

    if max_length >= child_len
      xml.dup

    elsif xml.is_a?(Nokogiri::XML::Text)
      last = max_length - omit_len
      unless last.negative?
        text = xml.content
        text =
          if opt[:content] || ((html = xml.to_s) == text)
            # No HTML entities, just simple characters.
            last = text.rindex(separator, last) || last if separator
            # noinspection RubyMismatchedArgumentType
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
              str_len = str.bytesize
              if str_len > last
                part << str.first(last)
                break
              elsif str_len.positive?
                part << str
                last -= str_len
              end
              entity     = "&#{code};"
              entity_len = entity.bytesize
              next if code.blank? || (entity_len > last)
              last -= entity_len
              code  = lookup[code] unless code.delete_prefix!('#')
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
      node      = blank_node_copy(xml)
      node_len  = node.to_s.bytesize
      remaining = max_length - node_len
      if remaining.positive?
        text = xml_truncate(xml.children.first, remaining, **opt)
        size = text ? (opt[:content] ? text.content : text.to_s).bytesize : 0
        if size >= omit_len
          node << text
        elsif max_length >= (node_len + omit_len)
          node << Nokogiri::XML::Text.new(omission, doc)
        end
      end
      if node.children.present?
        node
      elsif max_length >= omit_len
        Nokogiri::XML::Text.new(omission, doc)
      end

    else
      node         = blank_node_copy(xml)
      remaining    = max_length
      has_omission = false
      xml.children.each do |child|
        if remaining < omit_len
          break
        elsif remaining == omit_len
          node << Nokogiri::XML::Text.new(omission, doc) unless has_omission
          break
        elsif (child = xml_truncate(child, remaining, **opt)).nil?
          return
        else
          content   = child.content
          child_len = (opt[:content] ? content : child.to_s).bytesize
          break if (child_len > remaining) && node.children.present?
          remaining   -= child_len
          has_omission = content.end_with?(omission)
          node << child
        end
      end
      node if node.children.present?
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Copy of an XML node without its children.
  #
  # @param [Nokogiri::XML::Node] node
  #
  # @return [Nokogiri::XML::Node]
  #
  def blank_node_copy(node)
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
    base.extend(self)
  end

end

__loading_end(__FILE__)
