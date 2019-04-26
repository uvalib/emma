# app/models/api_title_metadata_complete_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/title_metadata_complete'

# ApiTitleMetadataCompleteList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_metadata_complete_list
#
class ApiTitleMetadataCompleteList < Api::Message

  schema do
    has_many  :allows,       String
    attribute :limit,        Integer
    has_many  :links,        Link
    attribute :next,         String
    has_many  :titles,       TitleMetadataComplete
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
