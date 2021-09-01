# app/records/bs/record/link.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Link
#
# @attr [String] href
# @attr [String] rel
#
# @see https://apidocs.bookshare.org/reference/index.html#_link
#
class Bs::Record::Link < Bs::Api::Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :href
    has_one   :rel
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
    href.to_s
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
    rel.to_s
  end

end

__loading_end(__FILE__)
