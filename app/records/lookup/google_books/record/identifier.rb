# app/records/lookup/google_books/record/identifier.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Industry standard identifiers for this volume.
#
# @attr [String] type                 %w[ISBN_10 ISBN_13 ISSN OTHER]
# @attr [String] identifier
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
#--
# noinspection LongLine
#++
class Lookup::GoogleBooks::Record::Identifier < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :type
    has_one :identifier
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def initialize(src = nil, **opt)
    if src.is_a?(String)
      src = PublicationIdentifier.cast(src)
      src &&= { type: src.type.to_s, identifier: src.value }
    end
    super
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # to_s
  #
  # @return [String]
  #
  def to_s
    t = type.presence&.downcase
    t = 'isbn' if t&.start_with?('isbn')
    [t, identifier].compact_blank!.join(':')
  end

  # blank?
  #
  def blank?
    type.blank? && identifier.blank?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Defined so that an instance of this class has a signature similar to
  # PublicationIdentifier.
  #
  # @return [String]
  #
  def value
    identifier.to_s
  end

end

__loading_end(__FILE__)
