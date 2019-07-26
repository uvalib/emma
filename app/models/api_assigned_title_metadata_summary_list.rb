# app/models/api_assigned_title_metadata_summary_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/assigned_title_metadata_summary'
require_relative 'api/link'
require_relative 'api/status_model'
require_relative 'api/common/link_methods'

# ApiAssignedTitleMetadataSummaryList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_assigned_title_metadata_summary_list
#
# NOTE: This duplicates:
# @see ApiTitleMetadataSummaryList
#
# noinspection RubyClassModuleNamingConvention
class ApiAssignedTitleMetadataSummaryList < Api::Message

  schema do
    has_many  :allows,       AllowsType
    attribute :limit,        Integer
    has_many  :links,        Api::Link
    has_one   :message,      Api::StatusModel
    attribute :next,         String
    has_many  :titles,       Api::AssignedTitleMetadataSummary
    attribute :totalResults, Integer
  end

  include Api::Common::LinkMethods

end

__loading_end(__FILE__)
