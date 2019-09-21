# app/controllers/concerns/serialization_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SerializationConcern
#
module SerializationConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'SerializationConcern')
  end

  include PaginationHelper

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
    make_opt, render_opt = partition_options(opt, :separator, :name)
    item = { response: item } unless item.is_a?(Hash) && (item.size == 1)
    text = make_xml(item, **make_opt)
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
  # @param [Object] item
  # @param [String] separator
  # @param [String] name              Node name if item.respond_to?(:to_xml).
  # @param [Api::Serializer::Base] serializer
  #
  # @return [String]
  #
  def make_xml(item, separator: "\n", name: nil, serializer: nil)
    if item.is_a?(Hash)
      return if item.blank?
      serializer ||= Api::Serializer::Xml::Base.new(nil)
      make_opt = { separator: separator, serializer: serializer }
      item.map { |k, v|
        value = make_xml(v, **make_opt)
        next if value.nil? && !serializer.render_nil?
        name  = serializer.element_render_name(k)
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Response values for serializing the index page to JSON or XML.
  #
  # @param [Api::Message, nil] list
  #
  # @return [Hash]
  #
  def index_values(list = nil)
    {
      list: page_items,
      properties: {
        total: total_items,
        limit: (list.limit if list.respond_to?(:limit)),
        links: (list.links if list.respond_to?(:links)),
      }
    }
  end

  # Response values for serializing the show page to JSON or XML.
  #
  # @param [Hash]   items
  #
  # @option items [Symbol] :as        Either :hash or :array is required.
  #
  # @return [Hash, Array]
  #
  def show_values(**items)
    if items.delete(:as) == :array
      items.values
    else
      items
    end
  end

end

__loading_end(__FILE__)
