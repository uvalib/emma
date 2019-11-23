# app/records/bs/shared/category_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to categories.
#
module Bs::Shared::CategoryMethods

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    name.to_s
  end

  # Translate to Bookshare category if necessary.
  #
  # @return [String]
  # @return [nil]                     If not translatable.
  #
  def bookshare_category
    name.to_s
  end

end

__loading_end(__FILE__)
