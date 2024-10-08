# app/records/bv_download/api/record/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definition of the #schema method used within the class definition to declare
# the serializable data elements associated with the class.
#
# @see Api::Record::Schema
#
module BvDownload::Api::Record::Schema

  extend ActiveSupport::Concern

  include Api::Record::Schema

  module ClassMethods
    include BvDownload::Api::Schema
    include Api::Record::Schema::ClassMethods
  end

end

__loading_end(__FILE__)
