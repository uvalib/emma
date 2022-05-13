# app/records/lookup/world_cat/shared/response_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to message elements supporting error reporting.
#
module Lookup::WorldCat::Shared::ResponseMethods
  include Lookup::RemoteService::Shared::ResponseMethods
  include Lookup::WorldCat::Shared::CommonMethods
end

__loading_end(__FILE__)
