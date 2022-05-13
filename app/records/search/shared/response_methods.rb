# app/records/search/shared/response_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to message elements supporting error reporting.
#
module Search::Shared::ResponseMethods
  include Api::Shared::ResponseMethods
  include Search::Shared::CommonMethods
end

__loading_end(__FILE__)
