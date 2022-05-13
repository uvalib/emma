# app/records/lookup/crossref/api/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Values related to the details of serialization/de-serialization.
#
# @see Lookup::RemoteService::Api::Schema
#
module Lookup::Crossref::Api::Schema

  include Lookup::Crossref::Api::Common
  include Lookup::RemoteService::Api::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # service_name
  #
  # @return [String]
  #
  def service_name
    'Lookup::Crossref'
  end

end

__loading_end(__FILE__)
