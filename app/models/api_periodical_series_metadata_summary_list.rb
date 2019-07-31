# app/models/api_periodical_series_metadata_summary_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/periodical_series_metadata_summary'
require_relative 'api/status_model'

# ApiPeriodicalSeriesMetadataSummaryList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_series_metadata_summary_list
#
# noinspection RubyClassModuleNamingConvention
class ApiPeriodicalSeriesMetadataSummaryList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,       AllowsType
    attribute :limit,        Integer
    has_many  :links,        Api::Link
    has_one   :message,      Api::StatusModel
    attribute :next,         String
    has_many  :periodicals,  Api::PeriodicalSeriesMetadataSummary
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
