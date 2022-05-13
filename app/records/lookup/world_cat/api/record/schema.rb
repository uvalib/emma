# app/records/lookup/world_cat/api/record/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definition of the #schema method used within the class definition to declare
# the serializable data elements associated with the class.
#
# @see Lookup::RemoteService::Api::Record::Schema
#
module Lookup::WorldCat::Api::Record::Schema

  extend ActiveSupport::Concern

  include Lookup::RemoteService::Api::Record::Schema

  module ClassMethods
    include Lookup::WorldCat::Api::Schema
    include Lookup::RemoteService::Api::Record::Schema::ClassMethods
  end

end

__loading_end(__FILE__)
