# app/records/lookup/google_books/api/serializer/obj.rb
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
class Lookup::GoogleBooks::Api::Serializer::Obj < Lookup::RemoteService::Api::Serializer::Obj

  include Lookup::GoogleBooks::Api::Serializer::Obj::Schema
  include Lookup::GoogleBooks::Api::Serializer::Obj::Associations

end

__loading_end(__FILE__)
