# app/records/ingest/api/serializer/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions used within the #schema block when it is executed in the context
# of a serializer class definition.
#
# @see Api::Serializer::Associations
#
module Ingest::Api::Serializer::Associations

  extend ActiveSupport::Concern

  include Api::Serializer::Associations

  module ClassMethods

    include Ingest::Api::Serializer::Schema
    include Api::Serializer::Associations::ClassMethods

  end

end

__loading_end(__FILE__)
