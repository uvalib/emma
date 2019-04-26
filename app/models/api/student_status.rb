# app/models/api/student_status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::StudentStatus
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_studentstatus
#
class Api::StudentStatus < Api::Record::Base

  schema do
    attribute :grade,            Grade
    attribute :organizationName, String
  end

end

__loading_end(__FILE__)
