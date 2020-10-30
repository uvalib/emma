# app/records/bs/record/contributor_name.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ContributorName
#
# @attr [String]                  displayName
# @attr [String]                  indexName
# @attr [Array<Bs::Record::Link>] links
#
# @see https://apidocs.bookshare.org/reference/index.html#_contributor_name
#
class Bs::Record::ContributorName < Bs::Api::Record

  include Bs::Shared::LinkMethods

  schema do
    has_one   :displayName
    has_one   :indexName
    has_many  :links,       Bs::Record::Link
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
