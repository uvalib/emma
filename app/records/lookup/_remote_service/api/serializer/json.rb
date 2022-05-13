# app/records/lookup/_remote_service/api/serializer/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process JSON data.
#
class Lookup::RemoteService::Api::Serializer::Json < Api::Serializer::Json

  include Lookup::RemoteService::Api::Serializer::Json::Schema
  include Lookup::RemoteService::Api::Serializer::Json::Associations

end

__loading_end(__FILE__)
