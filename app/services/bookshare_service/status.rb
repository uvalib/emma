# app/services/bookshare_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module BookshareService::Status

  include ApiService::Status

  # ===========================================================================
  # :section: ApiService::Status overrides
  # ===========================================================================

  public

  # Indicate whether the service is operational.
  #
  # @return [Array<(TrueClass,nil)>]
  # @return [Array<(FalseClass,String)>]
  #
  def active_status(...)
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
