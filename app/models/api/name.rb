# app/models/api/name.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/link'

# Api::Name
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_name
#
class Api::Name < Api::Record::Base

  schema do
    attribute :firstName, String
    attribute :lastName,  String
    has_many  :links,     Link
    attribute :middle,    String
    attribute :prefix,    String
    attribute :suffix,    String
  end

end

__loading_end(__FILE__)
