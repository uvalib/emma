# app/services/lookup_service/crossref/action.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for API requests.
#
module LookupService::Crossref::Action
  include LookupService::Crossref::Action::Journal
  include LookupService::Crossref::Action::Work
end

__loading_end(__FILE__)
