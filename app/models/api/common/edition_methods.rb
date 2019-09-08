# app/models/api/common/edition_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to periodical editions.
#
module Api::Common::EditionMethods

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
    editionName.to_s
  end

  # Return the unique identifier for the represented periodical edition.
  #
  # @return [String]
  #
  def identifier
    editionId.to_s
  end

end

__loading_end(__FILE__)
