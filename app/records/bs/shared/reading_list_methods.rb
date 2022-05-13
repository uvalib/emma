# app/records/bs/shared/reading_list_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to reading lists.
#
module Bs::Shared::ReadingListMethods

  include Bs::Shared::CommonMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Model
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
    find_item(:name) || identifier
  end

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # Return the unique identifier for the represented item.
  #
  # @return [String]
  #
  def identifier
    readingListId.to_s
  end

end

__loading_end(__FILE__)
