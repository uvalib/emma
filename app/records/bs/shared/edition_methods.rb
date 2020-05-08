# app/records/bs/shared/edition_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to periodical editions.
#
# Attributes supplied by the including module:
#
# @attr [String] editionId
# @attr [String] editionName
#
module Bs::Shared::EditionMethods

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
