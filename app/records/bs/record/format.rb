# app/records/bs/record/format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Format
#
# @attr [String] formatId
# @attr [String] name
#
# @see https://apidocs.bookshare.org/reference/index.html#_format
#
class Bs::Record::Format < Bs::Api::Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :formatId
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
    identifier
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
    formatId.to_s
  end

end

__loading_end(__FILE__)
