# app/models/api/reading_list_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'link'
require_relative 'common/link_methods'

# Api::ReadingListSubscription
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_reading_list_subscription
#
class Api::ReadingListSubscription < Api::Record::Base

  schema do
    has_many  :allows,  AllowsType
    attribute :enabled, Boolean
    has_many  :links,   Api::Link
  end

  include Api::Common::LinkMethods

end

__loading_end(__FILE__)
