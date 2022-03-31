# app/records/bs/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module Bs::Shared::IdentifierMethods

  include Api::Shared::IdentifierMethods

  # ===========================================================================
  # :section: Api::Shared::IdentifierMethods overrides
  # ===========================================================================

  public

  # The ISBN.
  #
  # @return [String]
  # @return [nil]                     If the value cannot be determined.
  #
  def isbn
    isbn13
  end

  # Related ISBNs omitting the main ISBN if part of the data array.
  #
  # @return [Array<String>]
  #
  def related_isbns
    # noinspection RailsParamDefResolve
    Array.wrap(try(:relatedIsbns)).compact_blank.uniq - Array.wrap(isbn)
  end

end

__loading_end(__FILE__)
