# app/records/bs/message/user_message_detail_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserMessageDetailList
#
# @attr [Array<Bs::Record::Link>]              links
# @attr [Array<Bs::Record::UserMessageDetail>] messages
#
# @see https://apidocs.bookshare.org/membership/index.html#_user_message_detail_list
#
class Bs::Message::UserMessageDetailList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :links,    Bs::Record::Link
    has_many :messages, Bs::Record::UserMessageDetail
  end

end

__loading_end(__FILE__)
