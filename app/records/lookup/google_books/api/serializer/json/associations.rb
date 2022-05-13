# app/records/lookup/google_books/api/serializer/json/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides for JSON serializers.
#
# @see Lookup::RemoteService::Api::Serializer::Json::Associations
#
module Lookup::GoogleBooks::Api::Serializer::Json::Associations

  extend ActiveSupport::Concern

  include Lookup::RemoteService::Api::Serializer::Json::Associations

  #--
  # noinspection LongLine
  #++
  module ClassMethods
    include Lookup::GoogleBooks::Api::Serializer::Json::Schema
    include Lookup::RemoteService::Api::Serializer::Json::Associations::ClassMethods
  end

end

__loading_end(__FILE__)
