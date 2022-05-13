# app/records/lookup/google_books/shared/date_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to dates.
#
module Lookup::GoogleBooks::Shared::DateMethods
  include Lookup::RemoteService::Shared::DateMethods
  include Lookup::GoogleBooks::Shared::CommonMethods
end

__loading_end(__FILE__)
