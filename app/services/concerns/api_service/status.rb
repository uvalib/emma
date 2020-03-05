# app/services/concerns/api_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module ApiService::Status

  extend self

  # Indicate whether the service is operational.
  #
  def active?(*)
    raise 'To be overridden'
  end

end

__loading_end(__FILE__)
