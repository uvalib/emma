# app/models/api_status_model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

# ApiStatusModel
#
# NOTE: This duplicates Api::StatusModel
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_status_model
#
class ApiStatusModel < Api::Message

  schema do
    attribute :key,      String
    has_many  :messages, String
  end

end

__loading_end(__FILE__)
