# app/records/bs/message/user_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserSubscription
#
# @see Bs::Record::UserSubscription
#
class Bs::Message::UserSubscription < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::SubscriptionMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::UserSubscription

end

__loading_end(__FILE__)
