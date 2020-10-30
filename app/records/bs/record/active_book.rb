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
    has_one   :activeTitleId
    has_many  :allows,        AllowsType
    has_one   :assignedBy
    has_one   :book,          Bs::Record::TitleMetadataSummary
    has_one   :dateAdded,     IsoDate
    has_one   :format,        Bs::Record::Format
    has_one   :lastUpdated,   IsoDate
    has_many  :links,         Bs::Record::Link
    has_one   :size,          Integer
    has_one   :status,        Bs::Record::StatusModel
  end

end

__loading_end(__FILE__)
