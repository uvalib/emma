# app/helpers/serialization_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting non-HTML rendering.
#
module SerializationHelper

  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the ultimate target format is HTML.
  #
  # @param [Hash, nil] p              Default: `params`.
  #
  def rendering_html?(p = nil)
    p ||= params
    fmt = p[:format].to_s.downcase
    (fmt == 'html') || (respond_to?(:request) && request.format.html?)
  end

  # Indicate whether the ultimate target format is something other than HTML.
  #
  # @param [Hash, nil] p              Default: `params`.
  #
  # @note Currently unused.
  #
  def rendering_non_html?(p = nil)
    !rendering_html?(p)
  end

  # Indicate whether the ultimate target format is JSON.
  #
  # @param [Hash, nil] p              Default: `params`.
  #
  # @note Currently unused.
  #
  def rendering_json?(p = nil)
    p ||= params
    fmt = p[:format].to_s.downcase
    (fmt == 'json') || (respond_to?(:request) && request.format.json?)
  end

  # Indicate whether the ultimate target format is XML.
  #
  # @param [Hash, nil] p              Default: `params`.
  #
  # @note Currently unused.
  #
  def rendering_xml?(p = nil)
    p ||= params
    fmt = p[:format].to_s.downcase
    (fmt == 'xml') || (respond_to?(:request) && request.format.xml?)
  end

  # Indicate whether the request originated from an HTML page.
  #
  # NOTE: This is probably insufficient.
  #
  def posting_html?
    return false unless respond_to?(:request) && !request.get?
    # noinspection RubyResolve
    request.format.html? || (request.format.js? && !!request.xhr?)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Serialize an item to JSON format.
  #
  # @param [any, nil] item
  # @param [Hash]     opt             Passed to #to_json.
  #
  # @return [String]
  #
  def make_json(item, **opt)
    item.to_json(**opt)
  end

  # Serialize an item to XML format.
  #
  # @param [any, nil]        item
  # @param [String]          separator
  # @param [String]          name       Node name if item.respond_to?(:to_xml).
  # @param [Api::Serializer] serializer
  #
  # @return [String]                  XML serialization of *item*.
  # @return [nil]                     If *item* is *nil* or an empty collection
  #
  def make_xml(item, separator: "\n", name: nil, serializer: nil)
    return if item.blank?
    # noinspection RubyMismatchedArgumentType
    if item.is_a?(Hash)
      serializer ||= Search::Api::Serializer::Xml.new
      make_opt     = { separator: separator, serializer: serializer }
      item.map { |k, v|
        value = make_xml(v, **make_opt)
        next if value.nil? && !serializer.render_nil?
        name  = serializer.element_render_name(k)
        value = "#{separator}#{value}#{separator}" if value.end_with?('>')
        "<#{name}>#{value}</#{name}>"
      }.compact.join(separator).presence

    elsif item.is_a?(Array)
      serializer ||= Search::Api::Serializer::Xml.new
      make_opt     = { separator: separator, serializer: serializer }
      item.map { |v| make_xml(v, **make_opt) }.compact.join(separator).presence

    elsif item.respond_to?(:to_xml)
      serializer ||= item.serializer(:xml)
      name       ||= serializer.element_render_name(item)
      remove_xml_prolog(item.to_xml(wrap: name))

    elsif !item.nil?
      CGI.escape_html(item.to_s)
    end
  end

  # @private
  XML_PROLOG = Api::Serializer::Xml::XML_PROLOG

  # add_xml_prolog
  #
  # @param [any, nil] item            String
  #
  # @return [String]
  #
  def add_xml_prolog(item)
    text = item.to_s
    text.start_with?(XML_PROLOG) ? text : "#{XML_PROLOG}\n#{text}"
  end

  # remove_xml_prolog
  #
  # @param [any, nil] item            String
  # @param [Boolean]  aggressive      If *true*, check all lines.
  #
  # @return [String]
  #
  def remove_xml_prolog(item, aggressive: false)
    text = item.to_s
    if aggressive
      text.split("\n").map { |line|
        line.delete_prefix!(XML_PROLOG)&.lstrip || line
      }.join("\n")
    elsif text.start_with?(XML_PROLOG)
      text.delete_prefix(XML_PROLOG).lstrip
    else
      text
    end
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
