# app/models/api/reading_list_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::ReadingListSubscription
#
# @attr [Array<AllowsType>] allows
# @attr [Boolean]           enabled
# @attr [Array<Api::Link>]  links
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list_subscription
#
class Api::ReadingListSubscription < Api::Record::Base

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,  AllowsType
    attribute :enabled, Boolean
    has_many  :links,   Api::Link
  end

end

__loading_end(__FILE__)
