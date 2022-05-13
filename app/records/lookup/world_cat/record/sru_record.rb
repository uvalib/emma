# app/records/lookup/world_cat/record/sru_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Partial record schema for WorldCat API results.
#
# @attr [String] recordSchema   'info:srw/schema/1/dc'
# @attr [String] recordPacking  'xml'
#
# @see https://developer.api.oclc.org/wcv1#operations-SRU-search-sru
#
class Lookup::WorldCat::Record::SruRecord < Lookup::WorldCat::Api::Record

  include Lookup::WorldCat::Shared::CreatorMethods
  include Lookup::WorldCat::Shared::DateMethods
  include Lookup::WorldCat::Shared::IdentifierMethods
  include Lookup::WorldCat::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :recordSchema                                   if EXT
    has_one :recordPacking                                  if EXT
    has_one :recordData,    Lookup::WorldCat::Record::Data
  end

end

__loading_end(__FILE__)
