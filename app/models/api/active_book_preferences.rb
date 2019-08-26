# app/models/api/active_book.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/link_methods'
require_relative 'format'

# Api::ActiveBookPreferences
#
# @attr [Array<AllowsType>]  allows
# @attr [Api::Format]        format
# @attr [String]             language
# @attr [Array<Api::Link>]   links
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_book_preferences
#
class Api::ActiveBookPreferences < Api::Record::Base

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,   AllowsType
    attribute :format,   Api::Format
    attribute :language, String
    has_many  :links,    Api::Link
  end

end

__loading_end(__FILE__)
