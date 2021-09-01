# app/records/bs/record/grade.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Grade
#
# @attr [String]                  gradeCode
# @attr [String]                  gradeId    *deprecated*
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  name
#
# @see https://apidocs.bookshare.org/reference/index.html#_grade
#
class Bs::Record::Grade < Bs::Api::Record

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :gradeCode
    has_one   :gradeId                                      # NOTE: deprecated
    has_many  :links,     Bs::Record::Link
    has_one   :name
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
    name.to_s
  end

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # Return the unique identifier for the represented item.
  #
  # @return [String]
  #
  def identifier
    gradeCode&.to_s || gradeId.to_s
  end

end

__loading_end(__FILE__)
