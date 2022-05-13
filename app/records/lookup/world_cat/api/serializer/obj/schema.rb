# app/records/lookup/world_cat/api/serializer/obj/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Obj-specific definition overrides for serialization.
#
# @see Lookup::RemoteService::Api::Serializer::Obj::Schema
#
module Lookup::WorldCat::Api::Serializer::Obj::Schema

  include Lookup::WorldCat::Api::Serializer::Schema
  include Lookup::RemoteService::Api::Serializer::Obj::Schema

end

__loading_end(__FILE__)
