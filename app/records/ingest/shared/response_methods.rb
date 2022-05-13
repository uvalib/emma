# app/records/ingest/shared/response_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to message elements supporting error reporting.
#
module Ingest::Shared::ResponseMethods
  include Api::Shared::ResponseMethods
  include Ingest::Shared::CommonMethods
end

__loading_end(__FILE__)
