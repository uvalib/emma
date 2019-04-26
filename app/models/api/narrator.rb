# app/models/api/narrator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::Narrator
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_narrator
#
class Api::Narrator < Api::Record::Base

  schema do
    attribute :gender, Gender
    attribute :name,   String
    attribute :type,   NarratorType
  end

end

__loading_end(__FILE__)
