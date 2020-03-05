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

  include ParamsHelper
  include PaginationHelper
  include SerializationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Response values for serializing the index page to JSON or XML.
  #
  # @param [*, nil] list
  #
  # @return [Hash{Symbol=>Array,Hash}]
  #
  # noinspection RubyNilAnalysis
  def index_values(list = nil)
    limit =
      if list.is_a?(Api::Record) && list.respond_to?(:limit)
        list.limit
      elsif list.is_a?(Array)
        list.size
      end
    {
      list: page_items.map { |item| show_values(item) },
      properties: {
        total: total_items,
        limit: limit,
        links: (list.links if list.respond_to?(:links)),
      }
    }
  end

  # Response values for serializing the show page to JSON or XML.
  #
  # @overload show_values(items, as: :array)
  #   @param [Hash] items
  #   @return [Array]
  #
  # @overload show_values(items, as: :hash)
  #   @param [Hash] items
  #   @return [Hash]
  #
  # @overload show_values(items)
  #   @param [Hash] items
  #   @return [Hash]
  #
  def show_values(items, as: :hash)
    (as == :array) ? items.values : items
  end

end

__loading_end(__FILE__)
