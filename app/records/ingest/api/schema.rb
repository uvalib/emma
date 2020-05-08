# app/records/ingest/api/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Values related to the details of serialization/de-serialization.
#
# @see Search::Api::Schema
#
module Ingest::Api::Schema

  include Search::Api::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # service_name
  #
  # @return [String]
  #
  def service_name
    'Ingest'
  end

end

__loading_end(__FILE__)
