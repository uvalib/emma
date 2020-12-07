# app/records/bs/message/user_message_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserMessageList
#
# @attr [Array<Bs::Record::Link>]        links
# @attr [Array<Bs::Record::UserMessage>] messages
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_message_list
#
class Bs::Message::UserMessageList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many :links,    Bs::Record::Link
    has_many :messages, Bs::Record::UserMessage
  end

end

__loading_end(__FILE__)
