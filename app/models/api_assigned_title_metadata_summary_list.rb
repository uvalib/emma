# app/models/api_assigned_title_metadata_summary_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiAssignedTitleMetadataSummaryList
#
# @attr [Array<AllowsType>]                        allows
# @attr [Integer]                                  limit
# @attr [Array<Api::Link>]                         links
# @attr [Api::StatusModel]                         message
# @attr [String]                                   next
# @attr [Array<Api::AssignedTitleMetadataSummary>] titles
# @attr [Integer]                                  totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_assigned_title_metadata_summary_list
#
# NOTE: This duplicates the form of:
# @see ApiTitleMetadataSummaryList
#
# noinspection RubyClassModuleNamingConvention
class ApiAssignedTitleMetadataSummaryList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,       AllowsType
    attribute :limit,        Integer
    has_many  :links,        Api::Link
    has_one   :message,      Api::StatusModel
    attribute :next,         String
    has_many  :titles,       Api::AssignedTitleMetadataSummary
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
