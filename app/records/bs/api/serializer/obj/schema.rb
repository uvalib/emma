# app/records/bs/api/serializer/obj/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Obj-specific definition overrides for serialization.
#
# @see Api::Serializer::Obj::Schema
#
module Bs::Api::Serializer::Obj::Schema

  include Bs::Api::Serializer::Schema
  include Api::Serializer::Obj::Schema

end

__loading_end(__FILE__)
