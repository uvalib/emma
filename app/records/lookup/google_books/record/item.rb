# app/records/lookup/google_books/record/item.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata record schema for Google Books API results.
#
# @attr [String]     kind
# @attr [String]     id
# @attr [String]     etag
# @attr [String]     selfLink
# @attr [VolumeInfo] volumeInfo
# @attr [UserInfo]   userInfo
# @attr [SaleInfo]   saleInfo
# @attr [AccessInfo] accessInfo
# @attr [SearchInfo] searchInfo
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
class Lookup::GoogleBooks::Record::Item < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CreatorMethods
  include Lookup::GoogleBooks::Shared::DateMethods
  include Lookup::GoogleBooks::Shared::IdentifierMethods
  include Lookup::GoogleBooks::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :kind
    has_one :id
    has_one :etag
    has_one :selfLink                                               if EXT
    has_one :volumeInfo,  Lookup::GoogleBooks::Record::VolumeInfo
    has_one :userInfo,    Lookup::GoogleBooks::Record::UserInfo     if ALL
    has_one :saleInfo,    Lookup::GoogleBooks::Record::SaleInfo     if EXT
    has_one :accessInfo,  Lookup::GoogleBooks::Record::AccessInfo   if EXT
    has_one :searchInfo,  Lookup::GoogleBooks::Record::SearchInfo   if EXT
  end

end

__loading_end(__FILE__)
