# app/records/bs/message/title_file_resource_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::TitleFileResourceList
#
# @attr [Array<Bs::Record::Link>]              links
# @attr [String]                               next
# @attr [Array<Bs::Record::TitleFileResource>] titleFileResources
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_file_resource_list
#
class Bs::Message::TitleFileResourceList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :links,              Bs::Record::Link
    attribute :next,               String
    has_many  :titleFileResources, Bs::Record::TitleFileResource
  end

end

__loading_end(__FILE__)
