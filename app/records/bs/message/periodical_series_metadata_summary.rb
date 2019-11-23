# app/records/bs/message/periodical_series_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::PeriodicalSeriesMetadataSummary
#
# @attr [Array<Bs::Record::Category>]          categories
# @attr [Array<String>]                        countries
# @attr [String]                               description
# @attr [Integer]                              editionCount
# @attr [String]                               externalCategoryCode
# @attr [String]                               issn
# @attr [Array<String>]                        languages
# @attr [Bs::Record::PeriodicalEditionSummary] latestEdition
# @attr [Array<Bs::Record::Link>]              links
# @attr [String]                               publisher
# @attr [String]                               seriesId
# @attr [SeriesType]                           seriesType
# @attr [String]                               title
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_series_metadata_summary
#
# NOTE: This duplicates:
# @see Bs::Record::PeriodicalSeriesMetadataSummary
#
# noinspection RubyClassModuleNamingConvention,DuplicatedCode
class Bs::Message::PeriodicalSeriesMetadataSummary < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::PeriodicalMethods

  schema do
    has_many  :categories,           Bs::Record::Category
    has_many  :countries,            String
    attribute :description,          String
    attribute :editionCount,         Integer
    attribute :externalCategoryCode, String
    attribute :issn,                 String
    has_many  :languages,            String
    has_one   :latestEdition,        Bs::Record::PeriodicalEditionSummary
    has_many  :links,                Bs::Record::Link
    attribute :publisher,            String
    attribute :seriesId,             String
    attribute :seriesType,           SeriesType
    attribute :title,                String
  end

end

__loading_end(__FILE__)
