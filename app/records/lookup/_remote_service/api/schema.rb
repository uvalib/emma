# app/records/lookup/_remote_service/api/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Values related to the details of serialization/de-serialization.
#
module Lookup::RemoteService::Api::Schema

  include Lookup::RemoteService::Api::Common
  include Api::Schema

  # ===========================================================================
  # :section: Api::Schema overrides
  # ===========================================================================

  public

  # service_name
  #
  # @return [String]
  #
  def service_name
    'Lookup::RemoteService'
  end

end

__loading_end(__FILE__)
