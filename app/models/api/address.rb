# app/models/api/address.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::Address
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_address
#
class Api::Address < Api::Record::Base

  schema do
    attribute :address1,   String
    attribute :address2,   String
    attribute :city,       String
    attribute :country,    String
    attribute :postalCode, String
    attribute :state,      String
  end

end

__loading_end(__FILE__)
