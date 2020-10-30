# app/records/bs/record/student_status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::StudentStatus
#
# @attr [Bs::Record:Grade] grade
# @attr [String]           organizationName
#
# @see https://apidocs.bookshare.org/reference/index.html#_studentstatus
#
class Bs::Record::StudentStatus < Bs::Api::Record

  schema do
    has_one   :grade,            Bs::Record::Grade
    has_one   :organizationName
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
