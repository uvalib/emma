# app/services/lookup_service/_remote_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::RemoteService::Common
#
module LookupService::RemoteService::Common

  include ApiService::Common

  include LookupService::RemoteService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, LookupService::RemoteService::Definition)
  end

end

__loading_end(__FILE__)
