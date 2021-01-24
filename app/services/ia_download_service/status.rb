# app/services/concerns/ia_download_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module IaDownloadService::Status

  # @private
  def self.included(base)
    base.send(:extend, self)
  end

  include ApiService::Status

end

__loading_end(__FILE__)
