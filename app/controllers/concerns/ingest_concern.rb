# app/controllers/concerns/ingest_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for access to the Ingest API service.
#
module IngestConcern

  extend ActiveSupport::Concern

  include ApiConcern
  include EngineConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the EMMA Federated Ingest API service.
  #
  # @return [IngestService]
  #
  def ingest_api
    engine = requested_engine(IngestService)
    # noinspection RubyMismatchedReturnType
    engine ? IngestService.new(base_url: engine) : api_service(IngestService)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Process the URL parameter for setting the ingest engine URL.
  #
  # @return [void]
  #
  def set_ingest_engine
    set_engine_callback(IngestService)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
