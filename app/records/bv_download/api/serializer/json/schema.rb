# app/records/bv_download/api/serializer/json/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# JSON-specific definition overrides for serialization.
#
# @see Api::Serializer::Json::Schema
#
module BvDownload::Api::Serializer::Json::Schema

  include BvDownload::Api::Serializer::Schema
  include Api::Serializer::Json::Schema

end

__loading_end(__FILE__)
