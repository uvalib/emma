# app/services/ingest_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ingest'

# Send messages through the EMMA Federated Ingestion API.
#
class IngestService < ApiService

  include Ingest

  # Include send/receive modules from "app/services/ingest_service/**.rb".
  include_submodules(self)

end

__loading_end(__FILE__)
