# app/records/lookup/world_cat/api/serializer/obj/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides for Obj serializers.
#
# @see Lookup::RemoteService::Api::Serializer::Obj::Associations
#
module Lookup::WorldCat::Api::Serializer::Obj::Associations

  extend ActiveSupport::Concern

  include Lookup::RemoteService::Api::Serializer::Obj::Associations

  #--
  # noinspection LongLine
  #++
  module ClassMethods
    include Lookup::WorldCat::Api::Serializer::Obj::Schema
    include Lookup::RemoteService::Api::Serializer::Obj::Associations::ClassMethods
  end

end

__loading_end(__FILE__)
