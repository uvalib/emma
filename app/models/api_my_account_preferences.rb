# app/models/api_my_account_preferences.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/format'
require 'api/link'

# ApiMyAccountPreferences
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_myaccount_preferences
#
class ApiMyAccountPreferences < Api::Message

  schema do
    attribute :allowAdultContent,    Boolean
    attribute :brailleCellLineWidth, Integer
    attribute :brailleFormat,        BrailleFormat
    attribute :brailleGrade,         BrailleGrade
    attribute :format,               Format
    attribute :language,             String
    has_many  :links,                Link
    attribute :showAllBooks,         Boolean
    attribute :useUeb,               Boolean
  end

end

__loading_end(__FILE__)
