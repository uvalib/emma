# app/services/concerns/api_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module ApiService::Status

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the service is operational.
  #
  # @return [Array(TrueClass,nil)]
  # @return [Array(FalseClass,String)]
  #
  def active_status(...)
    must_be_overridden
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
