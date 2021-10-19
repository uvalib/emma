# app/records/bs/message/user_account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserAccount
#
# @see Bs::Record::UserAccount
#
class Bs::Message::UserAccount < Bs::Api::Message

  include Bs::Shared::AccountMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::UserAccount

end

__loading_end(__FILE__)
