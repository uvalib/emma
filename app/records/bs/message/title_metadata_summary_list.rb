# app/records/bs/message/title_metadata_summary_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::TitleMetadataSummaryList
#
# @attr [Array<AllowsType>]                       allows
# @attr [Integer]                                 limit
# @attr [Array<Bs::Record::Link>]                 links
# @attr [Bs::Record::StatusModel]                 message
# @attr [String]                                  next
# @attr [Array<Bs::Record::TitleMetadataSummary>] titles
# @attr [Integer]                                 totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_metadata_summary_list
#
# NOTE: This duplicates the form of:
# @see Bs::Message::AssignedTitleMetadataSummaryList
#
class Bs::Message::TitleMetadataSummaryList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,       AllowsType
    has_one   :limit,        Integer
    has_many  :links,        Bs::Record::Link
    has_one   :message,      Bs::Record::StatusModel
    has_one   :next
    has_many  :titles,       Bs::Record::TitleMetadataSummary
    has_one   :totalResults, Integer
  end

end

__loading_end(__FILE__)
