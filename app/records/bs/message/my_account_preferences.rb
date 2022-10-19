# app/records/bs/message/my_account_preferences.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::MyAccountPreferences
#
# @attr [Boolean]                 allowAdultContent
# @attr [Integer]                 brailleCellLineWidth
# @attr [BsBrailleFmt]            brailleFormat
# @attr [BsBrailleGrade]          brailleGrade
# @attr [Bs::Record::Format]      format
# @attr [String]                  language
# @attr [Array<Bs::Record::Link>] links
# @attr [Boolean]                 showAllBooks
# @attr [Boolean]                 showRecommendations
# @attr [Boolean]                 useUeb
#
# @see https://apidocs.bookshare.org/reference/index.html#_myaccount_preferences
#
class Bs::Message::MyAccountPreferences < Bs::Api::Message

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :allowAdultContent,    Boolean
    has_one   :brailleCellLineWidth, Integer
    has_one   :brailleFormat,        BsBrailleFmt
    has_one   :brailleGrade,         BsBrailleGrade
    has_one   :format,               Bs::Record::Format
    has_one   :language
    has_many  :links,                Bs::Record::Link
    has_one   :showAllBooks,         Boolean
    has_one   :showRecommendations,  Boolean
    has_one   :useUeb,               Boolean
  end

end

__loading_end(__FILE__)
