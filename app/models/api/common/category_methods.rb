# app/models/api/common/category_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to categories.
#
module Api::Common::CategoryMethods

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

  # Translate to Bookshare category if necessary; return *nil* if not
  # translatable.
  #
  # @return [String, nil]
  #
  def bookshare_category
    name.to_s
  end

end

__loading_end(__FILE__)