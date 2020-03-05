# app/services/concerns/bookshare_service/status.rb
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
  # :section:
  # ===========================================================================

  public

  # Indicate whether the service is operational.
  #
  # This method overrides:
  # @see ApiService::Status#active?
  #
  def active?(*)
    BookshareService.new.get_title_count > 0
  end

end

__loading_end(__FILE__)
