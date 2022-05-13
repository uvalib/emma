# app/records/lookup/world_cat/api/serializer/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process JSON data.
#
#--
# noinspection LongLine
#++
class Lookup::WorldCat::Api::Serializer::Json < Lookup::RemoteService::Api::Serializer::Json

  include Lookup::WorldCat::Api::Serializer::Json::Schema
  include Lookup::WorldCat::Api::Serializer::Json::Associations

end

__loading_end(__FILE__)
