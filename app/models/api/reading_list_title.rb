# app/models/api/reading_list_title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

require_relative 'format'
require_relative 'link'
require_relative 'name'
require_relative 'common/title_methods'

# Api::ReadingListTitle
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_reading_list_title
#
class Api::ReadingListTitle < Api::Record::Base

  schema do
    has_many  :allows,           AllowsType
    has_many  :authors,          Api::Name
    attribute :available,        Boolean
    attribute :award,            String
    attribute :bookshareId,      String
    attribute :category,         String
    has_many  :composers,        Api::Name
    attribute :copyrightDate,    String
    attribute :dateAdded,        String
    has_many  :formats,          Api::Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Api::Link
    attribute :month,            Integer
    attribute :publishDate,      String
    attribute :ranking,          Integer
    attribute :seriesNumber,     String
    attribute :seriesTitle,      String
    attribute :subtitle,         String
    attribute :synopsis,         String
    attribute :title,            String
    attribute :titleContentType, String
    attribute :vocalParts,       String
    attribute :year,             Integer
  end

  include Api::Common::TitleMethods

end

__loading_end(__FILE__)
