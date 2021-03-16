# app/records/bs/message/user_message_detail.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserMessageDetail
#
# @attr [Array<BsAllowsType>]     allows
# @attr [String]                  createdBy
# @attr [IsoDate]                 createdDate
# @attr [IsoDate]                 expirationDate
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  messageId
# @attr [BsMessageType]           messageType
# @attr [BsMessagePriority]       priority
# @attr [Boolean]                 read
# @attr [String]                  text
#
# @see https://apidocs.bookshare.org/membership/index.html#_user_message_detail
#
# @see Bs::Record::UserMessageDetail (duplicate schema)
#
class Bs::Message::UserMessageDetail < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::MessageMethods

  schema do
    has_many  :allows,          BsAllowsType
    has_one   :createdBy
    has_one   :createdDate,     IsoDate
    has_one   :expirationDate,  IsoDate
    has_many  :links,           Bs::Record::Link
    has_one   :messageId
    has_one   :messageType,     BsMessageType
    has_one   :priority,        BsMessagePriority
    has_one   :read,            Boolean
    has_one   :text
  end

end

__loading_end(__FILE__)
