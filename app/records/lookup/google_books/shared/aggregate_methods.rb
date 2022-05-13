# app/records/lookup/google_books/shared/aggregate_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This is included in record classes that define :BASE_ELEMENT to confirm that
# they are intended to function as aggregates.
#
# @see Model::ClassMethods#validate_relations
#
module Lookup::GoogleBooks::Shared::AggregateMethods
  include Lookup::RemoteService::Shared::AggregateMethods
  include Lookup::GoogleBooks::Shared::CommonMethods
end

__loading_end(__FILE__)
