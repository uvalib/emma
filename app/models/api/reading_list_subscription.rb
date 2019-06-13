# app/models/api/reading_list_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

require_relative 'link'

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

end

__loading_end(__FILE__)
