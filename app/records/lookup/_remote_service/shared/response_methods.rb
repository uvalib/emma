# app/records/lookup/_remote_service/shared/response_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to message elements supporting error reporting.
#
module Lookup::RemoteService::Shared::ResponseMethods

  include Api::Shared::ResponseMethods
  include Lookup::RemoteService::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # api_records
  #
  # @return [Array<Api::Record>, nil]
  #
  def api_records
    Log.debug { "#{self.class}.#{__method__}: nil" }
  end

end

__loading_end(__FILE__)
