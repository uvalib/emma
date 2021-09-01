# app/controllers/concerns/ingest_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

# Controller support methods for access to the Ingest API service.
#
module IngestConcern

  extend ActiveSupport::Concern

  include ApiConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the EMMA Federated Ingest API service.
  #
  # @return [IngestService]
  #
  def ingest_api
    # noinspection RubyMismatchedReturnType
    api_service(IngestService)
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
