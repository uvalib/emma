# app/models/api/periodical_series_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::PeriodicalSeriesMetadataSummary
#
# @attr [Array<Api::Category>]          categories
# @attr [Array<String>]                 countries
# @attr [String]                        description
# @attr [Integer]                       editionCount
# @attr [String]                        externalCategoryCode
# @attr [String]                        issn
# @attr [Array<String>]                 languages
# @attr [Api::PeriodicalEditionSummary] latestEdition
# @attr [Array<Api::Link>]              links
# @attr [String]                        publisher
# @attr [String]                        seriesId
# @attr [String]                        title
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_series_metadata_summary
#
# NOTE: This duplicates:
# @see ApiPeriodicalSeriesMetadataSummary
#
# noinspection RubyClassModuleNamingConvention,DuplicatedCode
class Api::PeriodicalSeriesMetadataSummary < Api::Record::Base

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
