# app/models/api/grade.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/link'

# Api::Grade
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_grade
#
class Api::Grade < Api::Record::Base

  schema do
    attribute :gradeId, String
    has_many  :links,   Link
    attribute :name,    String
  end

end

__loading_end(__FILE__)
