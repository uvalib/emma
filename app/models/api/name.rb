# app/models/api/name.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

require_relative 'link'

# Api::Name
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_name
#
class Api::Name < Api::Record::Base

  schema do
    attribute :firstName, String
    attribute :lastName,  String
    has_many  :links,     Api::Link
    attribute :middle,    String
    attribute :prefix,    String
    attribute :suffix,    String
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
    full_name
  end

  # Display the name attributes in a single string.
  #
  # @param [Boolean] bib_order        If *true*, show in "bibliographic order"
  #                                     (lastName, firstName).
  #
  # @return [String]
  #
  def full_name(bib_order: false)
    parts =
      if bib_order
        [prefix, lastName, suffix, ',', firstName, middle]
      else
        [prefix, firstName, middle, lastName, suffix]
      end
    parts.join(' ').squish
  end

end

__loading_end(__FILE__)
