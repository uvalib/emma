# app/records/bs/record/narrator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Narrator
#
# @attr [Gender]       gender
# @attr [String]       name
# @attr [NarratorType] type
#
# @see https://apidocs.bookshare.org/reference/index.html#_narrator
#
class Bs::Record::Narrator < Bs::Api::Record

  schema do
    attribute :gender, Gender
    attribute :name,   String
    attribute :type,   NarratorType
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

end

__loading_end(__FILE__)
