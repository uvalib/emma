# app/services/bv_download_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module BvDownloadService::Status

  include ApiService::Status

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
