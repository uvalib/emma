# app/records/lookup/world_cat/api/serializer/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions used within the #schema block when it is executed in the context
# of a serializer class definition.
#
# @see Lookup::RemoteService::Api::Serializer::Associations
#
module Lookup::WorldCat::Api::Serializer::Associations

  extend ActiveSupport::Concern

  include Lookup::RemoteService::Api::Serializer::Associations

  module ClassMethods
    include Lookup::WorldCat::Api::Serializer::Schema
    include Lookup::RemoteService::Api::Serializer::Associations::ClassMethods
  end

end

__loading_end(__FILE__)
