# app/records/bs/record/active_book.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ActiveBook
#
# @attr [String]                           activeTitleId
# @attr [Array<AllowsType>]                allows
# @attr [String]                           assignedBy
# @attr [Bs::Record::TitleMetadataSummary] book
# @attr [IsoDate]                          dateAdded
# @attr [Bs::Record::Format]               format
# @attr [IsoDate]                          lastUpdated
# @attr [Array<Bs::Record::Link>]          links
# @attr [Integer]                          size
# @attr [Bs::Record::StatusModel]          status
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_book
#
class Bs::Record::ActiveBook < Bs::Api::Record

  include Bs::Shared::LinkMethods

  schema do
    attribute :activeTitleId, String
    has_many  :allows,        AllowsType
    attribute :assignedBy,    String
    has_one   :book,          Bs::Record::TitleMetadataSummary
    attribute :dateAdded,     IsoDate
    has_one   :format,        Bs::Record::Format
    attribute :lastUpdated,   IsoDate
    has_many  :links,         Bs::Record::Link
    attribute :size,          Integer
    has_one   :status,        Bs::Record::StatusModel
  end

end

__loading_end(__FILE__)
