# app/records/lookup/crossref/api/serializer/json/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# JSON-specific definition overrides for serialization.
#
# @see Lookup::RemoteService::Api::Serializer::Json::Schema
#
module Lookup::Crossref::Api::Serializer::Json::Schema

  include Lookup::Crossref::Api::Serializer::Schema
  include Lookup::RemoteService::Api::Serializer::Json::Schema

end

__loading_end(__FILE__)
