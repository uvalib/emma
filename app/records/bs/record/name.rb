# app/records/bs/record/name.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Name
#
# @attr [String]                  firstName
# @attr [String]                  lastName
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  middle
# @attr [String]                  prefix
# @attr [String]                  suffix
#
# @see https://apidocs.bookshare.org/reference/index.html#_name
#
class Bs::Record::Name < Bs::Api::Record

  include Bs::Shared::LinkMethods

  schema do
    has_one   :firstName
    has_one   :lastName
    has_many  :links,     Bs::Record::Link
    has_one   :middle
    has_one   :prefix
    has_one   :suffix
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
