# app/records/bs/record/title_file_resource.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::TitleFileResource
#
# @attr [IsoDate]                 lastModifiedDate
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  localURI
# @attr [String]                  mimeType
# @attr [String]                  size
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_file_resource
#
class Bs::Record::TitleFileResource < Bs::Api::Record

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    attribute :lastModifiedDate, IsoDate
    has_many  :links,            Bs::Record::Link
    attribute :localURI
    attribute :mimeType
    attribute :size                                       # TODO: not Integer?
  end

end

__loading_end(__FILE__)
