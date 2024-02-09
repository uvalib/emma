# app/records/lookup/google_books/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module Lookup::GoogleBooks::Shared::IdentifierMethods

  include Lookup::RemoteService::Shared::IdentifierMethods
  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::IdentifierMethods overrides
  # ===========================================================================

  public

  # A unique identifier for this catalog title.
  #
  # @return [String, nil]
  #
  def best_identifier
    (identifier_table[:lccn] || identifier_table.first)&.first&.to_s
  end

  # identifier_list
  #
  # @return [Array<String>]
  #
  def identifier_list
    @identifier_list ||=
      find_record_items(:industryIdentifiers)
        .compact_blank.sort_by! { |id| id_sort_key(id) }.map!(&:to_s)
  end

  # identifier_table
  #
  # @return [Hash{Symbol=>Array<PublicationIdentifier>}]
  #
  def identifier_table
    @identifier_table ||=
      identifier_list.reduce({}) { |result, id|
        type = id.sub(/:.*$/, '').to_sym
        id   = PublicationIdentifier.cast(id, invalid: true)
        id ? result.merge!(type => [*result[type], id]) : result
      }.transform_values! { |ids|
        ids.sort_by! { |id| -id.to_s.size }
      }
  end

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::IdentifierMethods overrides
  # ===========================================================================

  protected

  # @private
  # @type [Hash{Symbol=>String}]
  # noinspection SpellCheckingInspection
  ID_SORT = {
    lccn:    '   a',
    isbn_13: '   b',
    isbn_10: '   c',
    '':      'zzzz',
  }.freeze

  # id_sort_key
  #
  # @param [Lookup::GoogleBooks::Record::Identifier] id
  #
  # @return [Array<String>]
  #
  def id_sort_key(id)
    type = id.type.to_s.downcase
    type = ID_SORT[type.to_sym] || type.to_s
    [type, id.value]
  end

end

__loading_end(__FILE__)
