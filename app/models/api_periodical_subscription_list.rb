# app/models/api_periodical_subscription_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiOrganizationTypeList
#
# @attr [Array<Api::Link>]                   links
# @attr [Array<Api::PeriodicalSubscription>] titles
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_subscription_list
#
class ApiPeriodicalSubscriptionList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many :links,  Api::Link
    has_many :titles, Api::PeriodicalSubscription
  end

end

__loading_end(__FILE__)
