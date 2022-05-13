# app/records/lookup/world_cat/api/serializer/obj.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Ruby (hash) object representation.
#
#--
# noinspection LongLine
#++
class Lookup::WorldCat::Api::Serializer::Obj < Lookup::RemoteService::Api::Serializer::Obj

  include Lookup::WorldCat::Api::Serializer::Obj::Schema
  include Lookup::WorldCat::Api::Serializer::Obj::Associations

end

__loading_end(__FILE__)
