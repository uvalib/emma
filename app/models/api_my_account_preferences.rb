# app/models/api_my_account_preferences.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/artifact_methods'
require_relative 'api/common/link_methods'

# ApiMyAccountPreferences
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_myaccount_preferences
#
class ApiMyAccountPreferences < Api::Message

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods

  schema do
    attribute :allowAdultContent,    Boolean
    attribute :brailleCellLineWidth, Integer
    attribute :brailleFormat,        BrailleFormat
    attribute :brailleGrade,         BrailleGrade
    has_one   :format,               Api::Format
    attribute :language,             String
    has_many  :links,                Api::Link
    attribute :showAllBooks,         Boolean
    attribute :useUeb,               Boolean
  end

end

__loading_end(__FILE__)
