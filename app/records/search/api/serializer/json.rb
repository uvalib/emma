# app/records/search/api/serializer/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process JSON data.
#
class Search::Api::Serializer::Json < Api::Serializer::Json

  include Search::Api::Serializer::Json::Schema
  include Search::Api::Serializer::Json::Associations

end

__loading_end(__FILE__)
