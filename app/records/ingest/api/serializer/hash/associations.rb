# app/records/ingest/api/serializer/hash/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides to Ingest::Api::Serializer::Associations for Hash serializers.
#
# @see Api::Serializer::Hash::Associations
#
module Ingest::Api::Serializer::Hash::Associations

  extend ActiveSupport::Concern

  include ::Api::Serializer::Hash::Associations

  module ClassMethods

    include Ingest::Api::Serializer::Hash::Schema
    include ::Api::Serializer::Hash::Associations::ClassMethods

  end

end

__loading_end(__FILE__)