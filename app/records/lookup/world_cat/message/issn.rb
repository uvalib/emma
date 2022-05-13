# app/records/lookup/world_cat/message/issn.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Results from a WorldCat Metadata API v.1 Read search.
#
# Inside an XML '<oclcdcs>' element.
#
# @see https://developer.api.oclc.org/wcv1#operations-Read-read-issn
#
class Lookup::WorldCat::Message::Issn < Lookup::WorldCat::Api::Message

  include Lookup::WorldCat::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Lookup::WorldCat::Record::OclcDcs

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::ResponseMethods overrides
  # ===========================================================================

  public

  # api_records
  #
  # @return [Array<Lookup::WorldCat::Record::OclcDcs>]
  #
  def api_records
    Array.wrap(self)
  end

end

__loading_end(__FILE__)
