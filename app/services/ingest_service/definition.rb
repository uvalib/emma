# app/services/ingest_service/definition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Interface to the shared data structure which holds the definition of the EMMA
# Unified Ingest API requests and parameters.
#
module IngestService::Definition

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.include(ApiService::Definition)
  end

end

__loading_end(__FILE__)
