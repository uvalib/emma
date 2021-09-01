# app/records/bs/message/title_history_event_resource_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::TitleHistoryEventResourceList
#
# @attr [Array<Bs::Record::Link>]              links
# @attr [String]                               next
# @attr [Array<Bs::Record::TitleFileResource>] titleFileResources
#
# @see https://apidocs.bookshare.org/catalog/index.html#_title_history_event_resource_list
#
class Bs::Message::TitleHistoryEventResourceList < Bs::Api::Message

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :events, Bs::Record::TitleHistoryEvent
  end

end

__loading_end(__FILE__)
