# app/services/lookup_service/crossref/definition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Interface to the shared data structure which holds the definition of the API
# requests and parameters.
#
module LookupService::Crossref::Definition

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.include(LookupService::RemoteService::Definition)
  end

end

__loading_end(__FILE__)
