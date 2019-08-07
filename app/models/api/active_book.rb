# app/models/api/active_book.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/link_methods'
require_relative 'format'
require_relative 'status_model'
require_relative 'title_metadata_summary'

# Api::ActiveBook
#
# @attr [String]                    activeTitleId
# @attr [Array<AllowsType>]         allows
# @attr [String]                    assignedBy
# @attr [Api::TitleMetadataSummary] book
# @attr [String]                    dateAdded
# @attr [Api::Format]               format
# @attr [String]                    lastUpdated
# @attr [Array<Api::Link>]          links
# @attr [Integer]                   size
# @attr [Api::StatusModel]          status
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_book
#
class Api::ActiveBook < Api::Record::Base

  include Api::Common::LinkMethods

  schema do
    attribute :activeTitleId, String
    has_many  :allows,        AllowsType
    attribute :assignedBy,    String
    has_one   :book,          Api::TitleMetadataSummary
    attribute :dateAdded,     String
    has_one   :format,        Api::Format
    attribute :lastUpdated,   String
    has_many  :links,         Api::Link
    attribute :size,          Integer
    has_one   :status,        Api::StatusModel
  end

end

__loading_end(__FILE__)
