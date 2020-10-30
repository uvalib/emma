# app/records/bs/record/contributor.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Contributor
#
# @attr [Array<Bs::Record::Link>]     links
# @attr [Bs::Record::ContributorName] name
# @attr [ContributorType]             type
#
# @see https://apidocs.bookshare.org/reference/index.html#_contributor
#
class Bs::Record::Contributor < Bs::Api::Record

  include Bs::Shared::LinkMethods

  schema do
    has_many  :links, Bs::Record::Link
    has_one   :name,  Bs::Record::ContributorName
    has_one   :type,  ContributorType
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
  # @param [Boolean, String] role     If *true*, append the contributor type;
  #                                     if a string, display that as the role;
  #                                     otherwise no role is appended.
  #
  # @return [String]
  #
  def label(role = nil)
    role = type.to_s if role.is_a?(TrueClass)
    name.to_s.tap { |result| result << " (#{role})" if role.present? }
  end

end

__loading_end(__FILE__)
