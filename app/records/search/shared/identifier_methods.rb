# app/records/search/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module Search::Shared::IdentifierMethods

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
    @isbn ||= extract_isbns(:dc_identifier).first
  end

  # Related ISBNs omitting the main ISBN if part of the data array.
  #
  # @return [Array<String>]
  #
  def related_isbns
    @related_isbns ||= all_isbns - [isbn]
  end

  # The main and related ISBNs.
  #
  # @return [Array<String>]
  #
  def all_isbns
    @all_isbns ||= extract_isbns(*identifier_fields)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get only ISBN identifiers.
  #
  # @param [Array<Symbol>] fields
  #
  # @return [Array<String>]
  #
  def extract_isbns(*fields)
    vals = fields.flat_map { |field| get_values(field) }
    # noinspection RubyMismatchedReturnType
    vals.map { |v| v.to_s.remove(/\s/).sub!(/^isbn[^\d]*/, '') }.compact.uniq
  end

end

class PublicationIdentifierSet < Set

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def initialize(ids)
    ids = Array.wrap(ids).compact
    ids.map! { |v| PublicationIdentifier.cast(v, invalid: true) }
    ids.sort!
    super(ids)
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  def eql?(other)
    other = self.class.new(other) unless other.is_a?(self.class)
    intersect?(other)
  end

  def ==(other)
    # noinspection RubyMismatchedReturnType
    eql?(other)
  end

end

__loading_end(__FILE__)
