# app/records/ingest/api/serializer/obj.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Ruby (hash) object representation.
#
class Ingest::Api::Serializer::Obj < Api::Serializer::Obj

  include Ingest::Api::Serializer::Obj::Schema
  include Ingest::Api::Serializer::Obj::Associations

end

__loading_end(__FILE__)
