# app/records/ia_download/api/serializer/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process JSON data.
#
class IaDownload::Api::Serializer::Json < Api::Serializer::Json

  include IaDownload::Api::Serializer::Json::Schema
  include IaDownload::Api::Serializer::Json::Associations

end

__loading_end(__FILE__)
