# app/records/search/api/serializer/hash/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides for Hash serializers.
#
# @see Api::Serializer::Hash::Associations
#
module Search::Api::Serializer::Hash::Associations

  extend ActiveSupport::Concern

  include ::Api::Serializer::Hash::Associations

  module ClassMethods

    include Search::Api::Serializer::Hash::Schema
    include ::Api::Serializer::Hash::Associations::ClassMethods

  end

end

__loading_end(__FILE__)
