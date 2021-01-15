# app/services/bookshare_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module BookshareService::Status

  def self.included(base)
    base.send(:extend, self)
  end

  include ApiService::Status

  # ===========================================================================
  # :section: ApiService::Status overrides
  # ===========================================================================

  public

  # Indicate whether the service is operational.
  #
  # @return [(TrueClass,nil)]
  # @return [(FalseClass,String)]
  #
  def active_status(*)
    result = BookshareService.new.get_title_count
    if result.is_a?(Exception)
      active  = false
      message = result.message
    else
      active  = result.to_i.positive?
      message = nil
    end
    return active, message
  end

end

__loading_end(__FILE__)
