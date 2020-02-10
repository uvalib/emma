# app/records/bs/shared/reading_list_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to reading lists.
#
module Bs::Shared::ReadingListMethods

  # Listings of reading lists expect a non-blank description string.
  #
  # @type [String]
  #
  DEF_READING_LIST_DESCRIPTION = '(none)' # TODO: I18n

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
    respond_to?(:name) ? name.to_s : identifier
  end

  # Return the unique identifier for the represented item.
  #
  # @return [String]
  #
  def identifier
    readingListId.to_s
  end

end

__loading_end(__FILE__)