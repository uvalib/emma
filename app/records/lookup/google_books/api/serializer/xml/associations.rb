# app/records/lookup/google_books/api/serializer/xml/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides for XML serializers.
#
# @see Lookup::RemoteService::Api::Serializer::Xml::Associations
#
module Lookup::GoogleBooks::Api::Serializer::Xml::Associations

  extend ActiveSupport::Concern

  include Lookup::RemoteService::Api::Serializer::Xml::Associations

  #--
  # noinspection LongLine
  #++
  module ClassMethods
    include Lookup::GoogleBooks::Api::Serializer::Xml::Schema
    include Lookup::RemoteService::Api::Serializer::Xml::Associations::ClassMethods
  end

end

__loading_end(__FILE__)
