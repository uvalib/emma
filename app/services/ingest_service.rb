# app/services/ingest_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Transmit messages through the EMMA Unified Ingest API.
#
class IngestService < ApiService

  DESTRUCTIVE_TESTING = false

  include Ingest

  include IngestService::Properties
  include IngestService::Action
  include IngestService::Common
  include IngestService::Definition
  include IngestService::Status
  include IngestService::Testing

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION

    # @!method instance
    #   @return [IngestService]
    # @!method update
    #   @return [IngestService]
    class << self
    end

  end
  # :nocov:

end

__loading_end(__FILE__)
