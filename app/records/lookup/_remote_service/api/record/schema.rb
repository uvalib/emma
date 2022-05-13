# app/records/lookup/_remote_service/api/record/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definition of the #schema method used within the class definition to declare
# the serializable data elements associated with the class.
#
# @see Api::Record::Schema
#
module Lookup::RemoteService::Api::Record::Schema

  extend ActiveSupport::Concern

  include Api::Record::Schema

  module ClassMethods
    include Lookup::RemoteService::Api::Schema
    include Api::Record::Schema::ClassMethods
  end

end

__loading_end(__FILE__)
