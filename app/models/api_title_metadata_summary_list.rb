# app/models/api_title_metadata_summary_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/status_model'
require 'api/title_metadata_summary'

# ApiTitleMetadataSummaryList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_metadata_summary_list
#
class ApiTitleMetadataSummaryList < Api::Message

  schema do
    has_many  :allows,       String
    attribute :limit,        Integer
    has_many  :links,        Link
    attribute :message,      StatusModel
    attribute :next,         String
    has_many  :titles,       TitleMetadataSummary
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
