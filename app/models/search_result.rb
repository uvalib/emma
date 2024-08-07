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
  def initialize(attr = nil)
    super
  end

  # ===========================================================================
  # :section: IdMethods overrides
  # ===========================================================================

  public

  def oid(item = nil)
    item ? super : User.instance_for(self[:user_id])&.oid
  end

  def self.for_org(org = nil, **opt)
    org = extract_value!(org, opt, :org, __method__)
    org = oid(org)
    joins(:search_calls).where('users.org_id = ?', org, **opt)
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
