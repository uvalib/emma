# app/records/bs/api/serializer/hash.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Hash.
#
class Bs::Api::Serializer::Hash < ::Api::Serializer::Hash

  include Bs::Api::Serializer::Hash::Schema
  include Bs::Api::Serializer::Hash::Associations

end

__loading_end(__FILE__)
