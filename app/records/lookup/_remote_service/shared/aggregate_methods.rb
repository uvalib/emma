# app/records/lookup/_remote_service/shared/aggregate_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This is included in record classes that define :BASE_ELEMENT to confirm that
# they are intended to function as aggregates.
#
# @see Model::ClassMethods#validate_relations
#
module Lookup::RemoteService::Shared::AggregateMethods
  include Api::Shared::AggregateMethods
  include Lookup::RemoteService::Shared::CommonMethods
end

__loading_end(__FILE__)
