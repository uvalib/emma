# app/records/search/api/record/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions used within the #schema block when it is executed in the context
# of the class which includes this module.
#
# Definition of the #schema method which defines the serializable data elements
# for the including class.
#
# @see Api::Record::Schema
#
module Search::Api::Record::Schema

  extend ActiveSupport::Concern

  include ::Api::Record::Schema

  module ClassMethods

    include Search::Api::Schema
    include ::Api::Record::Schema::ClassMethods

  end

end

__loading_end(__FILE__)
