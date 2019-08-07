# app/models/api/contributor.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/link_methods'
require_relative 'contributor_name'

# Api::Contributor
#
# @attr [Array<Api::Link>]     links
# @attr [Api::ContributorName] name
# @attr [ContributorType]      type
#
# @see https://apidocs.bookshare.org/reference/index.html#_contributor
#
class Api::Contributor < Api::Record::Base

  include Api::Common::LinkMethods

  schema do
    has_many  :links, Api::Link
    has_one   :name,  Api::ContributorName
    attribute :type,  ContributorType
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
