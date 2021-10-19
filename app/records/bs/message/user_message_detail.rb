# app/records/bs/message/user_message_detail.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserMessageDetail
#
# @see Bs::Record::UserMessageDetail
#
class Bs::Message::UserMessageDetail < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::MessageMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::UserMessageDetail

end

__loading_end(__FILE__)
