# app/models/api/status_model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::StatusModel
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_status_model
#
class Api::StatusModel < Api::Record::Base

  schema do
    attribute :key,      String
    has_many  :messages, String
  end

end

__loading_end(__FILE__)
