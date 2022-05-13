# app/records/lookup/world_cat/record/data.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Partial record schema for WorldCat API results.
#
# @see https://developer.api.oclc.org/wcv1#operations-SRU-search-sru
#
class Lookup::WorldCat::Record::Data < Lookup::WorldCat::Api::Record

  include Lookup::WorldCat::Shared::CreatorMethods
  include Lookup::WorldCat::Shared::DateMethods
  include Lookup::WorldCat::Shared::IdentifierMethods
  include Lookup::WorldCat::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :oclcdcs, Lookup::WorldCat::Record::OclcDcs
  end

end

__loading_end(__FILE__)
