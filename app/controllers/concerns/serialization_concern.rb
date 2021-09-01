# app/controllers/concerns/serialization_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for non-HTML responses.
#
module SerializationConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'SerializationConcern')
  end

  include ParamsHelper
  include PaginationHelper
  include SerializationHelper

  include ApiConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render an item in JSON format.
  #
  # @param [*]    item
  # @param [Hash] opt                 Passed to #render.
  #
  def render_json(item, **opt)
    item = { response: item } unless item.is_a?(Hash) && (item.size == 1)
    item = item.merge(error: api_error_message) if api_error?
    text = make_json(item)
    render json: text, **opt
  end

  # Render an item in XML format.
  #
  # @param [*]    item
  # @param [Hash] opt                 Passed to #render except for:
  #
  # @option opt [String] :separator   Passed to #make_xml.
  # @option opt [String] :name        Passed to #make_xml.
  #
  def render_xml(item, **opt)
    opt, render_opt = partition_hash(opt, :separator, :name)
    item = { response: item } unless item.is_a?(Hash) && (item.size == 1)
    item = item.merge(error: api_error_message) if api_error?
    text = make_xml(item, **opt) || ''
    render xml: text, **render_opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Response values for serializing the index page to JSON or XML.
  #
  # @param [*] list
  #
  # @return [Hash{Symbol=>Array,Hash}]
  #
  def index_values(list = nil)
    # noinspection RubyCaseWithoutElseBlockInspection, RubyNilAnalysis
    limit =
      case list
        when Api::Record then list.try(:limit)
        when Array       then list.size
      end
    {
      list: page_items.map { |item| show_values(item, as: nil) },
      properties: {
        total: total_items,
        limit: limit,
        links: list.try(:links)
      }
    }
  end

  # Response values for serializing the show page to JSON or XML.
  #
  # @param [Hash, *]     items
  # @param [Symbol, nil] as           Either :hash or :array if given.
  #
  # @return [Hash{Symbol=>Hash,Array}]
  #
  def show_values(items, as: nil)
    as ||= :hash
    (as == :array) ? items.values : items
  end

end

__loading_end(__FILE__)
