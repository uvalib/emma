# app/records/bs/record/user_message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::UserMessage
#
# @attr [Array<BsAllowsType>]     allows
# @attr [IsoDate]                 createdDate
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  messageId
# @attr [BsMessageType]           messageType
# @attr [BsMessagePriority]       priority
# @attr [Boolean]                 read
# @attr [String]                  text
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_message
#
# @see Bs::Message::UserMessage (duplicate schema)
#
class Bs::Record::UserMessage < Bs::Api::Record

  include Bs::Shared::LinkMethods
  include Bs::Shared::MessageMethods

  schema do
    has_many  :allows,      BsAllowsType
    has_one   :createdDate, IsoDate
    has_many  :links,       Bs::Record::Link
    has_one   :messageId
    has_one   :messageType, BsMessageType
    has_one   :priority,    BsMessagePriority
    has_one   :read,        Boolean
    has_one   :text
  end

end

__loading_end(__FILE__)
