# app/records/lookup/_remote_service/api/serializer/json/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# JSON-specific definition overrides for serialization.
#
# @see Api::Serializer::Json::Schema
#
module Lookup::RemoteService::Api::Serializer::Json::Schema

  include Lookup::RemoteService::Api::Serializer::Schema
  include Api::Serializer::Json::Schema

end

__loading_end(__FILE__)
