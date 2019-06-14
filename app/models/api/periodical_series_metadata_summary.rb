# app/models/api/periodical_series_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

require_relative 'category'
require_relative 'link'
require_relative 'periodical_edition_summary'
require_relative 'common/periodical_methods'

# Api::PeriodicalSeriesMetadataSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_series_metadata_summary
#
# NOTE: This duplicates:
# @see ApiPeriodicalSeriesMetadataSummary
#
# noinspection RubyClassModuleNamingConvention
class Api::PeriodicalSeriesMetadataSummary < Api::Record::Base

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

  include Api::Common::PeriodicalMethods

end

__loading_end(__FILE__)
