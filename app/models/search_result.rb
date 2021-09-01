# app/models/search_result.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for a specific item within search results.
#
class SearchResult < ApplicationRecord

  include Emma::Debug

  has_and_belongs_to_many :search_calls

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  resourcify

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash, ActionController::Parameters, SearchResult, nil] attr
  # @param [Proc, nil] block
  #
  # @note - for dev traceability
  #
  def initialize(attr = nil, &block)
    __debug_items(binding)
    super(attr, &block)
  end

  # ===========================================================================
  # :section: ActiveRecord overrides
  # ===========================================================================

  public

  # Update database fields...
  #
  # @param [Hash, *] opt
  #
  # @return [void]
  #
  # This method overrides:
  # @see ActiveModel::AttributeAssignment#assign_attributes
  #
  def assign_attributes(opt)
    __debug_items(binding)
    super # TODO: ???
  rescue => error # TODO: remove - testing
    Log.warn { "#{__method__}: #{error.class}: #{error.message}"}
    raise error
  end

end

__loading_end(__FILE__)
