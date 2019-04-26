# app/models/api/periodical_series_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/category'
require 'api/periodical_edition_summary'
require 'api/link'

# Api::PeriodicalSeriesMetadataSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_series_metadata_summary
#
class Api::PeriodicalSeriesMetadataSummary < Api::Record::Base

  schema do
    has_many  :categories,           Category
    has_many  :countries,            String
    attribute :description,          String
    attribute :editionCount,         Integer
    attribute :externalCategoryCode, String
    attribute :issn,                 String
    has_many  :languages,            String
    attribute :latestEdition,        PeriodicalEditionSummary
    has_many  :links,                Link
    attribute :publisher,            String
    attribute :seriesId,             String
    attribute :title,                String
  end

end

__loading_end(__FILE__)
