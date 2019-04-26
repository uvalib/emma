# app/models/api/user_subscription_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::UserSubscriptionType
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_subscription_type
#
class Api::UserSubscriptionType < Api::Record::Base

  schema do
    attribute :description, String
    attribute :name,        String
  end

end

__loading_end(__FILE__)
