# app/records/bs/message/user_message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserMessage
#
# @attr [Array<AllowsType>]       allows
# @attr [IsoDate]                 createdDate
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  messageId
# @attr [MessageType]             messageType
# @attr [MessagePriority]         priority
# @attr [Boolean]                 read
# @attr [String]                  text
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_message
#
# @see Bs::Record::UserMessage (duplicate schema)
#
class Bs::Message::UserMessage < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::MessageMethods

  schema do
    has_many  :allows,      AllowsType
    has_one   :createdDate, IsoDate
    has_many  :links,       Bs::Record::Link
    has_one   :messageId
    has_one   :messageType, MessageType
    has_one   :priority,    MessagePriority
    has_one   :read,        Boolean
    has_one   :text
  end

end

__loading_end(__FILE__)
