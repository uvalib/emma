# app/models/api_assigned_title_metadata_summary_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/assigned_title_metadata_summary'

# ApiAssignedTitleMetadataSummaryList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_assigned_title_metadata_summary_list
#
class ApiAssignedTitleMetadataSummaryList < Api::Message

  schema do
    has_many  :allows,       String
    attribute :limit,        Integer
    has_many  :links,        Link
    attribute :message,      StatusModel
    attribute :next,         String
    has_many  :titles,       AssignedTitleMetadataSummary
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
