# app/records/lookup/google_books/api/record/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions used within the #schema block when it is executed in the context
# of the class which includes this module.
#
# @see Lookup::RemoteService::Api::Record::Associations
#
module Lookup::GoogleBooks::Api::Record::Associations

  extend ActiveSupport::Concern

  include Lookup::RemoteService::Api::Record::Associations

  module ClassMethods
    include Lookup::GoogleBooks::Api::Schema
    include Lookup::RemoteService::Api::Record::Associations::ClassMethods
  end

end

__loading_end(__FILE__)
