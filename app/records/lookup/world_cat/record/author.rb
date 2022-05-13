# app/records/lookup/world_cat/record/author.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Partial record schema for WorldCat API results.
#
# @see https://developer.api.oclc.org/wcv1#operations-tag-OpenSearch
#
class Lookup::WorldCat::Record::Author < Lookup::WorldCat::Api::Record

  include Lookup::WorldCat::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :name
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  def to_s
    name.to_s
  end

end

__loading_end(__FILE__)
