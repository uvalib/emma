# app/records/bs/message/periodical_series_metadata_summary_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::PeriodicalSeriesMetadataSummaryList
#
# @attr [Array<AllowsType>]                                  allows
# @attr [Integer]                                            limit
# @attr [Array<Bs::Record::Link>]                            links
# @attr [Bs::Record::StatusModel]                            message
# @attr [String]                                             next
# @attr [Array<Bs::Record::PeriodicalSeriesMetadataSummary>] periodicals
# @attr [Integer]                                            totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_series_metadata_summary_list
#
#--
# noinspection RubyClassModuleNamingConvention
#++
class Bs::Message::PeriodicalSeriesMetadataSummaryList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,       AllowsType
    has_one   :limit,        Integer
    has_many  :links,        Bs::Record::Link
    has_one   :message,      Bs::Record::StatusModel
    has_one   :next
    has_many  :periodicals,  Bs::Record::PeriodicalSeriesMetadataSummary
    has_one   :totalResults, Integer
  end

end

__loading_end(__FILE__)
