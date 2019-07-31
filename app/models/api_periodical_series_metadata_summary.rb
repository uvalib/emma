# app/models/api_periodical_series_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/periodical_series_metadata_summary'

# ApiPeriodicalSeriesMetadataSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_series_metadata_summary
#
# NOTE: This duplicates:
# @see Api::PeriodicalSeriesMetadataSummary
#
# noinspection RubyClassModuleNamingConvention,DuplicatedCode
class ApiPeriodicalSeriesMetadataSummary < Api::Message

  include Api::Common::LinkMethods
  include Api::Common::PeriodicalMethods

  schema do
    has_many  :categories,           Api::Category
    has_many  :countries,            String
    attribute :description,          String
    attribute :editionCount,         Integer
    attribute :externalCategoryCode, String
    attribute :issn,                 String
    has_many  :languages,            String
    has_one   :latestEdition,        Api::PeriodicalEditionSummary
    has_many  :links,                Api::Link
    attribute :publisher,            String
    attribute :seriesId,             String
    attribute :title,                String
  end

end

__loading_end(__FILE__)
