# app/records/bs/api/serializer/xml/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides to Bs::Api::Serializer::Associations for XML serializers.
#
# @see Api::Serializer::Xml::Associations
#
module Bs::Api::Serializer::Xml::Associations

  extend ActiveSupport::Concern

  include ::Api::Serializer::Xml::Associations

  module ClassMethods

    include Bs::Api::Serializer::Xml::Schema
    include ::Api::Serializer::Xml::Associations::ClassMethods

  end

end

__loading_end(__FILE__)
