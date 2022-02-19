# app/services/ingest_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Send messages through the EMMA Federated Ingestion API.
#
class IngestService < ApiService

  DESTRUCTIVE_TESTING = false

  #include Ingest # NOTE: commented-out

  # Include send/receive modules from "app/services/ingest_service/**.rb".
  include_submodules(self)

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # @!method instance
    #   @return [IngestService]
    # @!method update
    #   @return [IngestService]
    class << self
    end

    # :nocov:
  end

end

__loading_end(__FILE__)
