# app/records/search/api/serializer/obj/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides for Obj serializers.
#
# @see Api::Serializer::Obj::Associations
#
module Search::Api::Serializer::Obj::Associations

  extend ActiveSupport::Concern

  include Api::Serializer::Obj::Associations

  module ClassMethods
    include Search::Api::Serializer::Obj::Schema
    include Api::Serializer::Obj::Associations::ClassMethods
  end

end

__loading_end(__FILE__)
