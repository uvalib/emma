# app/helpers/serialization_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SerializationHelper
#
module SerializationHelper

  def self.included(base)
    __included(base, '[SerializationHelper]')
  end

  include ParamsHelper
  include PaginationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the ultimate target format is HTML.
  #
  # @param [Hash, nil] p              Default: `#params`.
  #
  def rendering_html?(p = nil)
    p ||= params
    fmt = p[:format].to_s.downcase
    (fmt == 'html') || (respond_to?(:request) && request.format.html?)
  end

  # Indicate whether the ultimate target format is something other than HTML.
  #
  # @param [Hash, nil] p              Default: `#params`.
  #
  def rendering_non_html?(p = nil)
    !rendering_html?(p)
  end

  # Indicate whether the ultimate target format is JSON.
  #
  # @param [Hash, nil] p              Default: `#params`.
  #
  def rendering_json?(p = nil)
    p ||= params
    fmt = p[:format].to_s.downcase
    (fmt == 'json') || (respond_to?(:request) && request.format.json?)
  end

  # Indicate whether the ultimate target format is XML.
  #
  # @param [Hash, nil] p              Default: `#params`.
  #
  def rendering_xml?(p = nil)
    p ||= params
    fmt = p[:format].to_s.downcase
    (fmt == 'xml') || (respond_to?(:request) && request.format.xml?)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render an item in JSON format.
  #
  # @param [Object] item
  # @param [Hash]   opt               Passed to #render.
  #
  def render_json(item, **opt)
    item = { response: item } unless item.is_a?(Hash) && (item.size == 1)
    item = item.merge(error: api_error_message) if api_error?
    text = make_json(item)
    render json: text, **opt
  end

  # Render an item in XML format.
  #
  # @param [Object] item
  # @param [Hash]   opt               Passed to #render except for:
  #
  # @option opt [String] :separator   Passed to #make_xml.
  # @option opt [String] :name        Passed to #make_xml.
  #
  def render_xml(item, **opt)
    opt, render_opt = partition_options(opt, :separator, :name)
    item = { response: item } unless item.is_a?(Hash) && (item.size == 1)
    item = item.merge(error: api_error_message) if api_error?
    text = make_xml(item, **opt) || ''
    render xml: text, **render_opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Serialize an item to JSON format.
  #
  # @param [Object] item
  # @param [Hash]   opt               Passed to #to_json.
  #
  # @return [String]
  #
  def make_json(item, **opt)
    item.to_json(**opt)
  end

  # Serialize an item to XML format.
  #
  # @param [*]               item
  # @param [String]          separator
  # @param [String]          name       Node name if item.respond_to?(:to_xml).
  # @param [Api::Serializer] serializer
  #
  # @return [String]
  # @return [nil]                     If *item* is *nil* or an empty collection
  #
  def make_xml(item, separator: "\n", name: nil, serializer: nil)
    if item.is_a?(Hash)
      return if item.blank?
      serializer ||= Bs::Api::Serializer::Xml.new
      make_opt = { separator: separator, serializer: serializer }
      # @type [Symbol] k
      # @type [*]      v
      item.map { |k, v|
        value = make_xml(v, **make_opt)
        next if value.nil? && !serializer.render_nil?
        name  = serializer.element_render_name(k)
        # noinspection RubyNilAnalysis
        value = "#{separator}#{value}#{separator}" if value.end_with?('>')
        "<#{name}>#{value}</#{name}>"
      }.compact.join(separator)

    elsif item.is_a?(Array)
      return if item.blank?
      make_opt = { separator: separator, serializer: serializer }
      item.map { |v| make_xml(v, **make_opt) }.compact.join(separator)

    elsif item.respond_to?(:to_xml)
      return if item.blank?
      name ||= (serializer || item.serializer(:xml)).element_render_name(item)
      item.to_xml(wrap: name)

    elsif !item.nil?
      CGI.escape_html(item.to_s)
    end
  end

end

__loading_end(__FILE__)
