# app/models/api/contributor_name.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::ContributorName
#
# @attr [String]           displayName
# @attr [String]           indexName
# @attr [Array<Api::Link>] links
#
# @see https://apidocs.bookshare.org/reference/index.html#_contributor_name
#
class Api::ContributorName < Api::Record::Base

  include Api::Common::LinkMethods

  schema do
    attribute :displayName, String
    attribute :indexName,   String
    has_many  :links,       Api::Link
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
    displayName&.to_s || indexName.to_s
  end

  # Return the unique identifier for the represented item.
  #
  # @return [String]
  #
  def identifier
    indexName&.to_s || displayName.to_s
  end

end

__loading_end(__FILE__)
