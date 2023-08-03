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
  # @param [SearchResult, Hash, nil] attr
  #
  # @note - for dev traceability
  #
  def initialize(attr = nil, &block)
    super
  end

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Update database fields...
  #
  # @param [SearchResult, Hash, nil] attr
  #
  # @return [void]
  #
  def assign_attributes(attr)
    __debug_items(binding)
    super
  end

end

__loading_end(__FILE__)
