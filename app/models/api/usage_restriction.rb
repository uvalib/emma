# app/models/api/usage_restriction.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::UsageRestriction
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_usage_restriction
#
class Api::UsageRestriction < Api::Record::Base

  schema do
    attribute :name,               String
    attribute :usageRestrictionId, String
  end

end

__loading_end(__FILE__)
