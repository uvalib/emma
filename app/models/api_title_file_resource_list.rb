# app/models/api_title_file_resource_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiTitleFileResourceList
#
# @attr [Array<Api::Link>]              links
# @attr [String]                        next
# @attr [Array<Api::TitleFileResource>] titleFileResources
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_file_resource_list
#
class ApiTitleFileResourceList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :links,              Api::Link
    attribute :next,               String
    has_many  :titleFileResources, Api::TitleFileResource
  end

end

__loading_end(__FILE__)
