# app/records/ingest/api/record/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions used within the #schema block when it is executed in the context
# of the class which includes this module.
#
# @see Api::Record::Associations
#
module Ingest::Api::Record::Associations

  extend ActiveSupport::Concern

  include Api::Record::Associations

  module ClassMethods

    include Ingest::Api::Schema
    include Api::Record::Associations::ClassMethods

  end

end

__loading_end(__FILE__)
