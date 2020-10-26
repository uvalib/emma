# app/records/search/api/serializer/xml/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides for XML serializers.
#
# @see Api::Serializer::Xml::Associations
#
module Search::Api::Serializer::Xml::Associations

  extend ActiveSupport::Concern

  include ::Api::Serializer::Xml::Associations

  module ClassMethods

    include Search::Api::Serializer::Xml::Schema
    include ::Api::Serializer::Xml::Associations::ClassMethods

  end

end

__loading_end(__FILE__)
