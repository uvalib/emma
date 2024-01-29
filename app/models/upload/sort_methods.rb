# app/models/upload/sort_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods for applying a sort order to sets of records.
#
module Upload::SortMethods

  include Record::Sortable

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sort order applied by default in #get_relation.
  #
  # @return [Symbol, String, Hash]
  #
  def default_sort
    { implicit_order_column => :desc }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
