# app/models/api/student_status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'grade'

# Api::StudentStatus
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_studentstatus
#
class Api::StudentStatus < Api::Record::Base

  schema do
    has_one   :grade,            Api::Grade
    attribute :organizationName, String
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    grade.to_s
  end

end

__loading_end(__FILE__)
