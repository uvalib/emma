# app/records/search/api/serializer/json/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides to Search::Api::Serializer::Associations for JSON serializers.
#
# @see Api::Serializer::Json::Associations
#
module Search::Api::Serializer::Json::Associations

  extend ActiveSupport::Concern

  include ::Api::Serializer::Json::Associations

  module ClassMethods

    include Search::Api::Serializer::Json::Schema
    include ::Api::Serializer::Json::Associations::ClassMethods

  end

end

__loading_end(__FILE__)
