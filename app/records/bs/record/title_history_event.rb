# app/records/bs/record/title_history_event.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::TitleHistoryEvent
#
# @attr [String]  action
# @attr [String]  comment
# @attr [IsoDate] date
# @attr [String]  format
# @attr [String]  personName
#
# @see https://apidocs.bookshare.org/catalog/index.html#_title_history_event
#
class Bs::Record::TitleHistoryEvent < Bs::Api::Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :action
    has_one   :comment
    has_one   :date,      IsoDate
    has_one   :format
    has_one   :personName
  end

end

__loading_end(__FILE__)
