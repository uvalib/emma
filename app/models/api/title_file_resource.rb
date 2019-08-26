# app/models/api/title_file_resource.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/link_methods'

# Api::TitleFileResource
#
# @attr [Array<AllowsType>] allows
# @attr [String]            lastModifiedDate
# @attr [Array<Api::Link>]  links
# @attr [String]            localURI
# @attr [String]            mimeType
# @attr [String]            size
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_file_resource
#
class Api::TitleFileResource < Api::Record::Base

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,            AllowsType
    attribute :lastModifiedDate,  String
    has_many  :links,             Api::Link
    attribute :localURI,          String
    attribute :mimeType,          String
    attribute :size,              String      # TODO: not Integer?
  end

end

__loading_end(__FILE__)
