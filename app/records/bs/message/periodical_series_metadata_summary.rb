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
# @attr [BsSeriesType]                         seriesType
# @attr [String]                               title
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_series_metadata_summary
#
# @note This duplicates Bs::Record::PeriodicalSeriesMetadataSummary
#
#--
# noinspection RubyClassModuleNamingConvention, DuplicatedCode
#++
class Bs::Message::PeriodicalSeriesMetadataSummary < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::PeriodicalMethods

  schema do
    has_many  :categories,           Bs::Record::Category
    has_many  :countries
    has_one   :description
    has_one   :editionCount,         Integer
    has_one   :externalCategoryCode
    has_one   :issn
    has_many  :languages
    has_one   :latestEdition,        Bs::Record::PeriodicalEditionSummary
    has_many  :links,                Bs::Record::Link
    has_one   :publisher
    has_one   :seriesId
    has_one   :seriesType,           BsSeriesType
    has_one   :title
  end

end

__loading_end(__FILE__)
