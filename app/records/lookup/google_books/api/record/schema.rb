# app/records/lookup/google_books/api/record/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definition of the #schema method used within the class definition to declare
# the serializable data elements associated with the class.
#
# @see Lookup::RemoteService::Api::Record::Schema
#
module Lookup::GoogleBooks::Api::Record::Schema

  extend ActiveSupport::Concern

  include Lookup::RemoteService::Api::Record::Schema

  module ClassMethods
    include Lookup::GoogleBooks::Api::Schema
    include Lookup::RemoteService::Api::Record::Schema::ClassMethods
  end

end

__loading_end(__FILE__)
