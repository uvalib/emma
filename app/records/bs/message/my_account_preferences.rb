# app/records/bs/message/my_account_preferences.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::MyAccountPreferences
#
# @attr [Boolean]                 allowAdultContent
# @attr [Integer]                 brailleCellLineWidth
# @attr [BrailleFormat]           brailleFormat
# @attr [BrailleGrade]            brailleGrade
# @attr [Bs::Record::Format]      format
# @attr [String]                  language
# @attr [Array<Bs::Record::Link>] links
# @attr [Boolean]                 showAllBooks
# @attr [Boolean]                 useUeb
#
# @see https://apidocs.bookshare.org/reference/index.html#_myaccount_preferences
#
class Bs::Message::MyAccountPreferences < Bs::Api::Message

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods

  schema do
    attribute :allowAdultContent,    Boolean
    attribute :brailleCellLineWidth, Integer
    attribute :brailleFormat,        BrailleFormat
    attribute :brailleGrade,         BrailleGrade
    has_one   :format,               Bs::Record::Format
    attribute :language,             String
    has_many  :links,                Bs::Record::Link
    attribute :showAllBooks,         Boolean
    attribute :useUeb,               Boolean
  end

end

__loading_end(__FILE__)
