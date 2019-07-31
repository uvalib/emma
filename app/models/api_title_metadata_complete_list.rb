# app/models/api_title_metadata_complete_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/title_metadata_complete'

# ApiTitleMetadataCompleteList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_metadata_complete_list
#
class ApiTitleMetadataCompleteList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,       AllowsType
    attribute :limit,        Integer
    has_many  :links,        Api::Link
    attribute :next,         String
    has_many  :titles,       Api::TitleMetadataComplete
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
