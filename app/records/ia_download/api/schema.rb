# app/records/ia_download/api/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Values related to the details of serialization/de-serialization.
#
module IaDownload::Api::Schema

  include IaDownload::Api::Common
  include Api::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The class name of the related service for logging.
  #
  # @return [String]
  #
  def service_name
    'IaDownload'
  end

end

__loading_end(__FILE__)
