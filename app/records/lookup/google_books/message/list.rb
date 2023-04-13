# app/records/lookup/google_books/message/list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::GoogleBooks::Message::List
#
# @attr [String]      kind            ("books#volumes")
# @attr [Integer]     totalItems
# @attr [Array<Item>] items
#
# @see https://developers.google.com/books/docs/v1/reference/volumes/list#response
#
class Lookup::GoogleBooks::Message::List < Lookup::GoogleBooks::Api::Message

  include Lookup::GoogleBooks::Shared::CollectionMethods
  include Lookup::GoogleBooks::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Lookup::GoogleBooks::Record::Item

  schema do
    has_one  :kind
    has_one  :totalItems, Integer
    has_many :items,      LIST_ELEMENT
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Overall total number of matching items.
  #
  # @return [Integer]
  #
  def total_results
    totalItems
  end

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::ResponseMethods overrides
  # ===========================================================================

  public

  # api_records
  #
  # @return [Array<Lookup::GoogleBooks::Record::VolumeInfo>]
  #
  def api_records
    Array.wrap(items).map(&:volumeInfo)
  end

end

__loading_end(__FILE__)
