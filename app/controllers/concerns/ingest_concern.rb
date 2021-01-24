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

  included do |base|
    __included(base, 'IngestConcern')
  end

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
    # noinspection RubyYardReturnMatch
    api_service(IngestService)
  end

end

__loading_end(__FILE__)
