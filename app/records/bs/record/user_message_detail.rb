# app/records/bs/record/user_message_detail.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::UserMessageDetail
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
# @see Bs::Message::UserMessageDetail (duplicate schema)
#
class Bs::Record::UserMessageDetail < Bs::Api::Record

  include Bs::Shared::LinkMethods
  include Bs::Shared::MessageMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

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
