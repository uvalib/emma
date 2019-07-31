# app/models/api/grade.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/link_methods'

# Api::Grade
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_grade
#
class Api::Grade < Api::Record::Base

  include Api::Common::LinkMethods

  schema do
    attribute :gradeId, String
    has_many  :links,   Api::Link
    attribute :name,    String
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

  # Return the unique identifier for the represented item.
  #
  # @return [String]
  #
  def identifier
    gradeId.to_s
  end

end

__loading_end(__FILE__)
