# app/records/bs/message/periodical_subscription_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::OrganizationTypeList
#
# @attr [Array<Bs::Record::Link>]                   links
# @attr [Array<Bs::Record::PeriodicalSubscription>] titles
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_subscription_list
#
class Bs::Message::PeriodicalSubscriptionList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many :links,  Bs::Record::Link
    has_many :titles, Bs::Record::PeriodicalSubscription
  end

end

__loading_end(__FILE__)
