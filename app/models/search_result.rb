# app/models/search_result.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for a specific item within search results.
#
class SearchResult < ApplicationRecord

  include Emma::Debug

  include Model

  include Record
  include Record::Assignable
  include Record::Authorizable

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  has_and_belongs_to_many :search_calls

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
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Update database fields...
  #
  # @param [Hash, ActionController::Parameters, SearchResult, nil] attr
  # @param [Hash, nil]                                             opt
  #
  # @return [void]
  #
  def assign_attributes(attr, opt = nil)
    __debug_items(binding)
    super
  end

end

__loading_end(__FILE__)
