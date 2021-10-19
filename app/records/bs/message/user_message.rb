# app/records/bs/message/user_message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserMessage
#
# @see Bs::Record::UserMessage
#
class Bs::Message::UserMessage < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::MessageMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::UserMessage

end

__loading_end(__FILE__)
