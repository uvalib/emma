# app/controllers/concerns/serialization_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for non-HTML responses.
#
module SerializationConcern

  extend ActiveSupport::Concern

  include SerializationHelper
  include SessionDebugHelper

  include ApiConcern
  include PaginationConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render an item in JSON format.
  #
  # @param [any, nil] item
  # @param [Hash]     opt             Passed to #render.
  #
  def render_json(item, **opt)
    item = { response: item } unless item.is_a?(Hash) && (item.size == 1)
    item = item.merge(error: api_exec_report) if api_error?
    text = make_json(item)
    render json: text, **opt
  end

  # Render an item in XML format.
  #
  # @param [any, nil] item
  # @param [Hash]     opt             Passed to #render except for:
  #
  # @option opt [String] :separator   Passed to #make_xml.
  # @option opt [String] :name        Passed to #make_xml.
  #
  def render_xml(item, **opt)
    xml_opt = opt.extract!(:separator, :name)
    if item.is_a?(Model)
      xml_opt[:name] ||= :response
    elsif item.is_a?(Hash)
      item = { response: item } unless item.size == 1
      item = item.merge(error: api_exec_report) if api_error?
    else
      item = { response: item }
    end
    text = make_xml(item, **xml_opt)
    text = add_xml_prolog(text)
    render xml: text, **opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Response values for serializing the index page to JSON or XML.
  #
  # @param [any, nil] list            Default: `paginator.page_items`
  # @param [Hash]     opt
  #
  # @option opt [Symbol, String] :wrap
  # @option opt [Symbol, String] :name  Default: :list
  #
  # @return [Hash]
  #
  def index_values(list = nil, **opt)
    wrap_name = opt.key?(:wrap) ? opt.delete(:wrap) : :response
    list_name = opt.key?(:name) ? opt.delete(:name) : :list
    item_name = opt.delete(:item)
    debug     = session_debug?

    items  = paginator&.page_items || list || []
    list ||= items

    prop = {
      total: paginator&.total_items || paginator&.item_count(list),
      limit: list.try(:limit),
      links: list.try(:links)
    }
    prop[:list_type] = list.class.name        if debug
    prop[:item_type] = items.first.class.name if debug

    if (elements = list.try(:elements))
      items = elements.map { _1.to_h(item: item_name) }
    elsif list.is_a?(Model)
      items = list.to_h(item: item_name)
      items = items[:titles] || items[:records] || items if items.size == 1
    elsif list.is_a?(Array)
      items = list.map { show_values(_1, as: nil) }
    elsif list.is_a?(Hash)
      items = list
    else
      items = [list]
    end

    items.try(:map!) { |v| { item_name => v } }       if item_name
    items = { properties: prop, list_name => items }  if list_name
    items = { wrap_name => items }                    if wrap_name
    # noinspection RubyMismatchedReturnType
    items
  end

  # Response values for serializing the show page to JSON or XML.
  #
  # @param [any, nil]       item
  # @param [Symbol, nil]    as        Either :hash or :array if given.
  # @param [Symbol, String] name
  #
  # @return [Hash]
  #
  def show_values(item, as: nil, name: nil, **)
    case
      when as == :array      then entry = item.try(:values) || Array.wrap(item)
      when item.is_a?(Model) then entry = item.to_h(item: name)
      else                        entry = item
    end
    name ||= :item unless entry.is_a?(Hash)
    # noinspection RubyMismatchedReturnType
    name ? { name.to_sym => entry } : entry
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
