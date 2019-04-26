# app/models/api/format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::Format
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_format
#
class Api::Format < Api::Record::Base

  schema do
    attribute :formatId, String
    attribute :name,     String
  end

end

__loading_end(__FILE__)
