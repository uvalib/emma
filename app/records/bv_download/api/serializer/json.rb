# app/records/bv_download/api/serializer/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process JSON data.
#
class BvDownload::Api::Serializer::Json < Api::Serializer::Json

  include BvDownload::Api::Serializer::Json::Schema
  include BvDownload::Api::Serializer::Json::Associations

end

__loading_end(__FILE__)
