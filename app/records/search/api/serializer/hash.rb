# app/records/search/api/serializer/hash.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Hash.
#
class Search::Api::Serializer::Hash < Api::Serializer::Hash

  include Search::Api::Serializer::Hash::Schema
  include Search::Api::Serializer::Hash::Associations

end

__loading_end(__FILE__)
