# app/records/lookup/world_cat/api/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Values related to the details of serialization/de-serialization.
#
# @see Lookup::RemoteService::Api::Schema
#
module Lookup::WorldCat::Api::Schema

  include Lookup::WorldCat::Api::Common
  include Lookup::RemoteService::Api::Schema

  # ===========================================================================
  # :section: Api::Schema overrides
  # ===========================================================================

  public

  # The class name of the related service for logging.
  #
  # @return [String]
  #
  def service_name
    'Lookup::WorldCat'
  end

  # default_serializer_type
  #
  # @return [Symbol]
  #
  def default_serializer_type
    :xml
  end

end

__loading_end(__FILE__)
