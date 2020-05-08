# app/records/ingest/api/serializer/hash/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Hash-specific definition overrides for serialization.
#
# @see Api::Serializer::Hash::Schema
#
module Ingest::Api::Serializer::Hash::Schema

  include Ingest::Api::Serializer::Schema
  include ::Api::Serializer::Hash::Schema

end

__loading_end(__FILE__)
