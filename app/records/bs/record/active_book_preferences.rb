# app/records/bs/record/active_book_preferences.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ActiveBookPreferences
#
# @attr [Array<BsAllowsType>]     allows
# @attr [Bs::Record::Format]      format
# @attr [String]                  language
# @attr [Array<Bs::Record::Link>] links
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_book_preferences
#
class Bs::Record::ActiveBookPreferences < Bs::Api::Record

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,   BsAllowsType
    has_one   :format,   Bs::Record::Format
    has_one   :language
    has_many  :links,    Bs::Record::Link
  end

end

__loading_end(__FILE__)
