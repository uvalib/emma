# app/records/bs/record/narrator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Narrator
#
# @attr [BsGender]       gender
# @attr [String]         name
# @attr [BsNarratorType] type
#
# @see https://apidocs.bookshare.org/reference/index.html#_narrator
#
class Bs::Record::Narrator < Bs::Api::Record

  schema do
    has_one   :gender, BsGender
    has_one   :name
    has_one   :type,   BsNarratorType
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
