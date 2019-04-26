# app/models/api/link.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::Link
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_link
#
class Api::Link < Api::Record::Base

  schema do
    attribute :href, String
    attribute :rel,  String
  end

end

__loading_end(__FILE__)
