# app/records/bs/message/assigned_title_metadata_summary_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::AssignedTitleMetadataSummaryList
#
# @attr [Array<AllowsType>]                               allows
# @attr [Integer]                                         limit
# @attr [Array<Bs::Record::Link>]                         links
# @attr [Bs::Record::StatusModel]                         message
# @attr [String]                                          next
# @attr [Array<Bs::Record::AssignedTitleMetadataSummary>] titles
# @attr [Integer]                                         totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_assigned_title_metadata_summary_list
#
# NOTE: This duplicates the form of:
# @see Bs::Message::TitleMetadataSummaryList
#
#--
# noinspection RubyClassModuleNamingConvention
#++
class Bs::Message::AssignedTitleMetadataSummaryList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,       AllowsType
    has_one   :limit,        Integer
    has_many  :links,        Bs::Record::Link
    has_one   :message,      Bs::Record::StatusModel
    has_one   :next
    has_many  :titles,       Bs::Record::AssignedTitleMetadataSummary
    has_one   :totalResults, Integer
  end

end

__loading_end(__FILE__)
