# app/records/bs/record/reading_list_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ReadingListSubscription
#
# @attr [Array<AllowsType>]        allows
# @attr [Boolean]                  enabled
# @attr [Array<Bs::Record::Link>]  links
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list_subscription
#
class Bs::Record::ReadingListSubscription < Bs::Api::Record

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,  AllowsType
    attribute :enabled, Boolean
    has_many  :links,   Bs::Record::Link
  end

end

__loading_end(__FILE__)
