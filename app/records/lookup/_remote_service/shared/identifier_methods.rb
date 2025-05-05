# app/records/lookup/_remote_service/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module Lookup::RemoteService::Shared::IdentifierMethods

  include Api::Shared::IdentifierMethods
  include Lookup::RemoteService::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A unique identifier for this catalog title.
  #
  # @return [String, nil]
  #
  def best_identifier
    identifier_table.first&.first&.to_s
  end

  # identifier_list
  #
  # @return [Array<String>]
  #
  def identifier_list(field = nil)
    identifier_table.values.flatten.sort_by { id_sort_key(_1) }.map!(&:to_s)
  end

  # identifier_table
  #
  # @return [Hash{Symbol=>Array<PublicationIdentifier>}]
  #
  def identifier_table
    must_be_overridden
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @private
  # @type [Hash{Symbol=>String}]
  ID_SORT = {
    isbn_13: '   a',
    isbn_10: '   b',
    '':      'zzzz',
  }.freeze

  # id_sort_key
  #
  # @param [PublicationIdentifier] id
  #
  # @return [Array<String>]
  #
  def id_sort_key(id)
    type = id.type
    type = id.isbn13? ? :isbn_13 : :isbn_10 if type == :isbn
    type = ID_SORT[type] || type.to_s
    [type, id.value]
  end

  # ===========================================================================
  # :section: Api::Shared::IdentifierMethods overrides
  # ===========================================================================

  public

  # The ISBN (if present), preferring ISBN_13 over ISBN_10.
  #
  # @return [String, nil]
  #
  def isbn
    identifier_table[:isbn]&.first&.to_s
  end

end

__loading_end(__FILE__)
