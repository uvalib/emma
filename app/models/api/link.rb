# app/models/api/link.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::Link
#
# @attr [String] href
# @attr [String] rel
#
# @see https://apidocs.bookshare.org/reference/index.html#_link
#
class Api::Link < Api::Record::Base

  schema do
    attribute :href, String
    attribute :rel,  String
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
